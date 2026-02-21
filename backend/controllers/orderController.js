const Order = require("../models/Order");
const Listing = require("../models/Listing");
const Notification = require("../models/Notification");
const VolunteerProfile = require("../models/VolunteerProfile");
const User = require("../models/User");
const mongoose = require("mongoose");

// Create a new order
exports.createOrder = async (req, res) => {
    let session;
    try {
        console.log("ENTERING createOrder");
        session = await mongoose.startSession();
        session.startTransaction();
        const {
            listingId,
            buyerId,
            quantityOrdered,
            fulfillment,
            pickup,
            drop,
            pricing,
            specialInstructions
        } = req.body;

        // 1. Find the listing
        const listing = await Listing.findById(listingId).session(session);

        if (!listing) {
            throw new Error("Listing not found");
        }

        if (listing.status !== "active") {
            throw new Error(`Listing is no longer active (Status: ${listing.status})`);
        }

        // 2. Check quantity
        if (listing.remainingQuantity < quantityOrdered) {
            throw new Error(`Insufficient quantity. Only ${listing.remainingQuantity} left.`);
        }

        // 3. Check expiry
        if (new Date(listing.pickupWindow.to) < new Date()) {
            throw new Error("Listing has expired");
        }

        // 4. Create the order
        const initialStatus = fulfillment === "volunteer_delivery" ? "awaiting_volunteer" : "placed";
        const otp = Math.floor(1000 + Math.random() * 9000).toString(); // Generate 4-digit OTP
        const pOtp = fulfillment === "volunteer_delivery" ? Math.floor(1000 + Math.random() * 9000).toString() : null;

        const newOrder = new Order({
            listingId,
            sellerId: listing.sellerId,
            buyerId,
            quantityOrdered,
            fulfillment,
            status: initialStatus,
            pickup,
            drop,
            pricing,
            specialInstructions,
            pickupOtp: pOtp,
            handoverOtp: otp,
            timeline: { placedAt: new Date() }
        });

        await newOrder.save({ session });

        // 5. Update listing quantity
        listing.remainingQuantity -= quantityOrdered;

        // 6. Auto-complete if quantity hits 0
        if (listing.remainingQuantity === 0) {
            listing.status = "completed";
        }

        await listing.save({ session });

        // 6. Notify Seller and Buyer
        // Fetch buyer details within the same session so we can include them in the seller notification
        let buyer = null;
        try {
            if (typeof User.findById === 'function') {
                const maybeQuery = User.findById(buyerId);
                if (maybeQuery && typeof maybeQuery.session === 'function') {
                    buyer = await maybeQuery.session(session);
                } else if (maybeQuery && typeof maybeQuery.then === 'function') {
                    buyer = await maybeQuery;
                }
            }
        } catch (e) {
            // If tests mock User without a proper implementation, gracefully ignore and continue
            buyer = null;
        }

        const sellerNotification = {
            userId: listing.sellerId,
            type: "order_update",
            title: "📦 New Order Received",
            message: `${buyer && buyer.name ? buyer.name : 'A buyer'} just ordered ${quantityOrdered}x ${listing.foodName}.`,
            data: {
                orderId: newOrder._id,
                listingId: listing._id,
                buyer: {
                    id: buyer?._id,
                    name: buyer?.name,
                    email: buyer?.email,
                    phone: buyer?.phone,
                    addressText: buyer?.addressText
                },
                quantityOrdered,
                fulfillment,
                pickup,
                drop,
                placedAt: newOrder.timeline?.placedAt || newOrder.createdAt,
                action: "view_order"
            }
        };

        const buyerNotification = {
            userId: buyerId,
            type: "order_update",
            title: "✅ Order Placed Successfully",
            message: `Your order for ${quantityOrdered}x ${listing.foodName} has been placed! ${fulfillment === "volunteer_delivery" ? "A volunteer will be assigned soon." : "You can pick it up at the scheduled time."}`,
            data: {
                orderId: newOrder._id,
                listingId: listing._id,
                action: "view_order"
            }
        };

        await Notification.create([sellerNotification, buyerNotification], { session, ordered: true });

        await session.commitTransaction();
        session.endSession();

        // If volunteer delivery, trigger matching
        if (fulfillment === "volunteer_delivery") {
            initiateVolunteerMatching(newOrder, listing);
        }

        res.status(201).json({
            message: "Order placed successfully",
            order: newOrder,
            remainingQuantity: listing.remainingQuantity
        });

    } catch (error) {
        if (session) {
            await session.abortTransaction();
            session.endSession();
        }
        console.error("Create Order Error:", error.message);
        console.error("Full error:", error);
        res.status(400).json({ error: error.message });
    }
};

// Get order by ID
exports.getOrderById = async (req, res) => {
    try {
        const { id } = req.params;
        const order = await Order.findById(id)
            .populate('listingId')
            .populate('sellerId', 'name email phone firebaseUid trustScore role addressText')
            .populate('buyerId', 'name email phone firebaseUid addressText')
            .populate('volunteerId', 'name email phone firebaseUid trustScore');

        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        res.status(200).json(order);
    } catch (error) {
        console.error("Get Order Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Get buyer's orders
exports.getBuyerOrders = async (req, res) => {
    try {
        const { buyerId } = req.params;
        const { status } = req.query;

        const query = { buyerId };
        if (status) query.status = status;

        const orders = await Order.find(query)
            .populate({
                path: "listingId",
                select: "foodName images pricing pickupAddressText pickupWindow safetyStatus isSafetyValidated"
            })
            .populate({
                path: "sellerId",
                select: "name email phone firebaseUid trustScore role addressText"
            })
            .populate({
                path: "volunteerId",
                select: "name phone trustScore"
            })
            .sort({ createdAt: -1 });

        res.status(200).json(orders);
    } catch (error) {
        console.error("Get Buyer Orders Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// 7. Get all orders for a seller
exports.getSellerOrders = async (req, res) => {
    try {
        const { sellerId } = req.params;
        const orders = await Order.find({ sellerId })
            .populate("listingId", "foodName foodType images pricing pickupAddressText pickupWindow")
            .populate("buyerId", "name phone addressText")
            .populate("volunteerId", "name phone trustScore")
            .sort({ createdAt: -1 });

        res.status(200).json(orders);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// 8. Get volunteer rescue requests (notifications)
exports.getVolunteerRescueRequests = async (req, res) => {
    try {
        const { volunteerId } = req.params;
        const notifications = await Notification.find({
            userId: volunteerId,
            type: "rescue_request",
            isRead: false
        }).sort({ createdAt: -1 });

        // Filter out notifications where the underlying order is no longer awaiting_volunteer
        // This handles cases where another volunteer accepted or the order timed out
        const filteredNotifications = [];
        for (const notif of notifications) {
            const orderId = notif.data?.orderId;
            if (orderId) {
                const order = await Order.findById(orderId).select('status');
                if (order && order.status === 'awaiting_volunteer') {
                    filteredNotifications.push(notif);
                } else if (order) {
                    // Auto-mark as read if order is no longer available
                    notif.isRead = true;
                    await notif.save();
                }
            } else {
                filteredNotifications.push(notif);
            }
        }

        res.status(200).json(filteredNotifications);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// 8b. Get volunteer orders
exports.getVolunteerOrders = async (req, res) => {
    try {
        const { volunteerId } = req.params;
        const { status } = req.query;

        const query = { volunteerId };
        if (status) query.status = status;

        const orders = await Order.find(query)
            .populate({
                path: "listingId",
                select: "foodName images pickupAddressText pickupWindow"
            })
            .populate({
                path: "buyerId",
                select: "name phone"
            })
            .populate({
                path: "sellerId",
                select: "name phone"
            })
            .sort({ createdAt: -1 });

        res.status(200).json(orders);
    } catch (error) {
        console.error("Get Volunteer Orders Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// 9. Accept a rescue request
exports.acceptRescueRequest = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { id } = req.params; // orderId
        const { volunteerId } = req.body;

        const order = await Order.findById(id).populate('listingId', 'foodName').session(session);

        if (!order) {
            throw new Error("Order not found");
        }

        if (order.status !== "awaiting_volunteer") {
            throw new Error(`Order cannot be accepted (Status: ${order.status})`);
        }

        // 1. Check volunteer concurrency limits
        const profile = await VolunteerProfile.findOne({ userId: volunteerId }).session(session);
        if (!profile) {
            throw new Error("Volunteer profile not found");
        }

        if (profile.availability.activeOrders >= profile.availability.maxConcurrentOrders) {
            throw new Error("You have reached your maximum concurrent rescue limit.");
        }

        // 2. Update order status and assign volunteer
        order.status = "volunteer_assigned";
        order.volunteerId = volunteerId;
        order.volunteerAssignedAt = new Date();
        order.timeline.acceptedAt = new Date();

        await order.save({ session });

        // 3. Update volunteer active orders
        profile.availability.activeOrders += 1;
        // Auto-disable availability if at limit (optional, but helps with matching)
        if (profile.availability.activeOrders >= profile.availability.maxConcurrentOrders) {
            profile.availability.isAvailable = false;
        }
        await profile.save({ session });

        // 4. Mark relevant notifications as read
        await Notification.updateMany(
            { "data.orderId": id, type: "rescue_request" },
            { isRead: true, readAt: new Date() },
            { session }
        );

        // Notify Buyer & Seller using insertMany for multiple docs in session
        await Notification.insertMany([
            {
                userId: order.buyerId,
                type: "order_update",
                title: "🚚 Volunteer Assigned",
                message: "A volunteer has accepted your rescue request and is on the way!",
                data: { orderId: order._id, status: "volunteer_assigned" }
            },
            {
                userId: order.sellerId,
                type: "order_update",
                title: "🤝 Volunteer Found",
                message: "A volunteer will arrive shortly to pick up the order.",
                data: { orderId: order._id, status: "volunteer_assigned" }
            },
            {
                userId: volunteerId,
                type: "order_update",
                title: "📦 Pickup Assignment",
                message: `You have been assigned to pick up ${order.quantityOrdered}x ${order.listingId?.foodName || 'food items'} from the seller.`,
                data: { 
                    orderId: order._id, 
                    status: "volunteer_assigned",
                    action: "pickup_from_seller"
                }
            }
        ], { session });

        await session.commitTransaction();
        session.endSession();

        res.status(200).json({ message: "Rescue request accepted", order });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error("Accept Rescue Error:", error);
        res.status(400).json({ error: error.message });
    }
};

// Update order status or other fields
exports.updateOrder = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;

        const order = await Order.findById(id);
        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        if (updates.status) {
            const oldStatus = order.status;
            order.status = updates.status;

            // If transitioning to a terminal status from an active one, cleanup volunteer capacity
            const terminalStatuses = ["delivered", "cancelled"];
            if (terminalStatuses.includes(updates.status) && !terminalStatuses.includes(oldStatus)) {
                if (order.volunteerId) {
                    await VolunteerProfile.findOneAndUpdate(
                        { userId: order.volunteerId },
                        {
                            $inc: { "availability.activeOrders": -1 },
                            $set: { "availability.isAvailable": true }
                        }
                    );

                    if (updates.status === "delivered") {
                        // Trust Score Bonus (+2)
                        await User.findByIdAndUpdate(order.volunteerId, { $inc: { trustScore: 2 } });
                        // Cap at 100
                        await User.findOneAndUpdate(
                            { _id: order.volunteerId, trustScore: { $gt: 100 } },
                            { $set: { trustScore: 100 } }
                        );
                    }
                }
            }
        }

        if (updates.fulfillment) {
            order.fulfillment = updates.fulfillment;
        }

        if (updates.payment) {
            order.payment = { ...order.payment.toObject(), ...updates.payment };
        }

        await order.save();

        // 4. Send Notification if status changed
        if (updates.status) {
            let title = "Order Update";
            let message = `Order #${order._id.toString().slice(-6)} is now ${updates.status.replace("_", " ")}`;

            // Tailor messages
            if (updates.status === "picked_up") {
                title = "🚚 Order Picked Up";
                message = "The volunteer has picked up your food!";
            } else if (updates.status === "delivered") {
                title = "✅ Order Delivered";
                message = "Enjoy your meal! The order has been delivered.";
            }

            // Notify Buyer
            await Notification.create({
                userId: order.buyerId,
                type: "order_update",
                title,
                message,
                data: { orderId: order._id, status: updates.status }
            });

            // Notify Seller if delivered or cancelled
            if (updates.status === "delivered" || updates.status === "cancelled") {
                await Notification.create({
                    userId: order.sellerId,
                    type: "order_update",
                    title,
                    message: updates.status === "delivered" ? "Your food rescue has been successfully completed!" : "The order was cancelled.",
                    data: { orderId: order._id, status: updates.status }
                });
            }
        }

        res.status(200).json({ message: "Order updated successfully", order });
    } catch (error) {
        console.error("Update Order Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// 10. Simple Status Update (backward compatibility)
exports.updateOrderStatus = async (req, res) => {
    return exports.updateOrder(req, res);
};

// Cancel order
exports.cancelOrder = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        const { id } = req.params;
        const { cancelledBy, reason } = req.body;

        const order = await Order.findById(id).session(session);
        if (!order) {
            throw new Error("Order not found");
        }

        if (order.status === "delivered" || order.status === "cancelled") {
            throw new Error(`Cannot cancel order with status: ${order.status}`);
        }

        // Restore listing quantity
        const listing = await Listing.findById(order.listingId).session(session);
        if (listing) {
            listing.remainingQuantity += order.quantityOrdered;
            if (listing.status === "completed" && listing.remainingQuantity > 0) {
                listing.status = "active";
            }
            await listing.save({ session });
        }

        // Update order
        order.status = "cancelled";
        order.cancellation = { cancelledBy, reason };
        order.timeline.cancelledAt = new Date();
        await order.save({ session });

        // If volunteer was assigned, decrement activeOrders and restore availability
        if (order.volunteerId) {
            await VolunteerProfile.findOneAndUpdate(
                { userId: order.volunteerId },
                {
                    $inc: { "availability.activeOrders": -1 },
                    $set: { "availability.isAvailable": true }
                },
                { session, returnDocument: 'after' }
            );
        }

        // --- Notify Parties ---
        const notifications = [];
        const shortId = order._id.toString().slice(-6);
        const title = "❌ Order Cancelled";
        const message = `Order #${shortId} has been cancelled by the ${cancelledBy}.`;

        // Always notify Buyer
        notifications.push({
            userId: order.buyerId,
            type: "order_update",
            title: cancelledBy === "buyer" ? "✅ Order Cancelled" : "❌ Order Cancelled",
            message: cancelledBy === "buyer" 
                ? `You have successfully cancelled order #${shortId}.`
                : `Your order #${shortId} has been cancelled by the ${cancelledBy}.`,
            data: { orderId: order._id, status: "cancelled" }
        });

        // Always notify Seller if they didn't cancel
        if (cancelledBy !== "seller") {
            notifications.push({
                userId: order.sellerId,
                type: "order_update",
                title,
                message,
                data: { orderId: order._id, status: "cancelled" }
            });
        }

        // Notify Volunteer if they didn't cancel and were assigned
        if (order.volunteerId && cancelledBy !== "volunteer") {
            notifications.push({
                userId: order.volunteerId,
                type: "order_update",
                title,
                message: `The rescue request for #${shortId} was cancelled.`,
                data: { orderId: order._id, status: "cancelled" }
            });
        }

        if (notifications.length > 0) {
            await Notification.insertMany(notifications, { session });
        }

        await session.commitTransaction();
        session.endSession();

        res.status(200).json({ message: "Order cancelled successfully", order });
    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error("Cancel Order Error:", error);
        res.status(400).json({ error: error.message });
    }
};

// Helper: Trigger volunteer matching
// 12. Report Emergency
exports.reportEmergency = async (req, res) => {
    try {
        const { id } = req.params;
        const { volunteerId, lat, lng, reason } = req.body;

        const order = await Order.findById(id);
        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        console.error(`[EMERGENCY] Order ${id} by Volunteer ${volunteerId} at ${lat}, ${lng}. Reason: ${reason}`);

        // Notify Buyer and Seller
        const notifications = [
            {
                userId: order.buyerId,
                type: "emergency",
                title: "⚠️ Delivery Alert",
                message: "A potential delay or issue has occurred with your delivery. We are looking into it.",
                data: { orderId: order._id, reason }
            },
            {
                userId: order.sellerId,
                type: "emergency",
                title: "⚠️ Delivery Alert",
                message: "An issue was reported for a rescue pickup. Please contact support if needed.",
                data: { orderId: order._id, reason }
            }
        ];

        await Notification.create(notifications, { ordered: true });

        // In a real app, you would also notify internal admins or dispatch.

        res.status(200).json({ message: "Emergency reported and parties notified" });

    } catch (error) {
        console.error("Report Emergency Error:", error);
        res.status(500).json({ error: error.message });
    }
};

async function initiateVolunteerMatching(order, listing) {
    try {
        console.log(`[Matching] Starting search for order ${order._id}`);

        let pickupGeo = listing.pickupGeo;

        // Fallback for legacy listings that might have 'geo' instead of 'pickupGeo'
        if (!pickupGeo || !pickupGeo.coordinates) {
            const legacyGeo = listing.get ? listing.get('geo') : listing.geo;
            if (legacyGeo && legacyGeo.coordinates) {
                console.log(`[Matching] Order ${order._id}: Using legacy 'geo' field for Listing ${listing._id}`);
                pickupGeo = legacyGeo;
            }
        }

        console.log(`[Matching] listing.pickupGeo raw:`, JSON.stringify(pickupGeo, null, 2));

        if (!pickupGeo || !pickupGeo.coordinates) {
            console.error(`[Matching] Order ${order._id}: Listing ${listing._id} has no geo coordinates! Check listing.pickupGeo.`);
            console.log(`[Matching] listing keys available:`, Object.keys(listing.toObject ? listing.toObject() : listing));
            return;
        }

        console.log(`[Matching] Order ${order._id}: Searching near ${pickupGeo.coordinates}`);

        const totalActiveVolunteers = await User.countDocuments({ role: "volunteer", isActive: true });
        console.log(`[Matching] [DEBUG] Total active volunteers in DB: ${totalActiveVolunteers}`);

        // 1. Find nearby volunteers with their availability profiles
        // Using aggregation for better filtering and distance calculation
        const matchingVolunteers = await User.aggregate([
            {
                $geoNear: {
                    near: pickupGeo,
                    distanceField: "distance",
                    maxDistance: 7000, // 7km
                    query: { role: "volunteer", isActive: true },
                    spherical: true
                }
            },
            {
                $lookup: {
                    from: "volunteerprofiles",
                    localField: "_id",
                    foreignField: "userId",
                    as: "profile"
                }
            },
            { $unwind: "$profile" },
            {
                $match: {
                    "profile.availability.isAvailable": true,
                    $expr: { $lt: ["$profile.availability.activeOrders", "$profile.availability.maxConcurrentOrders"] }
                }
            },
            {
                $addFields: {
                    // Score = (Distance Score 0-70) + (Trust Score 0-30)
                    distanceScore: {
                        $multiply: [
                            { $subtract: [1, { $divide: ["$distance", 7000] }] },
                            70
                        ]
                    },
                    trustWeight: { $multiply: [{ $ifNull: ["$trustScore", 50] }, 0.3] }
                }
            },
            {
                $project: {
                    _id: 1,
                    name: 1,
                    distance: 1,
                    matchScore: { $add: ["$distanceScore", "$trustWeight"] }
                }
            },
            { $sort: { matchScore: -1 } },
            { $limit: 10 }
        ]);

        console.log(`[Matching] Order ${order._id}: Step 1 - Found ${matchingVolunteers.length} qualified volunteers within 7km.`);

        // Debug: Log all users found near location regardless of availability/limit
        const allNearbyVolunteers = await User.aggregate([
            {
                $geoNear: {
                    near: pickupGeo,
                    distanceField: "distance",
                    maxDistance: 50000, // 50km for debug
                    query: { role: "volunteer" },
                    spherical: true
                }
            },
            {
                $lookup: {
                    from: "volunteerprofiles",
                    localField: "_id",
                    foreignField: "userId",
                    as: "profile"
                }
            },
            { $unwind: { path: "$profile", preserveNullAndEmptyArrays: true } }
        ]);

        console.log(`[Matching] [DEBUG] Volunteers within 50km (any status): ${allNearbyVolunteers.length}`);
        allNearbyVolunteers.forEach(v => {
            const avail = v.profile ? v.profile.availability.isAvailable : "NO PROFILE";
            const active = v.profile ? v.profile.availability.activeOrders : "N/A";
            const max = v.profile ? v.profile.availability.maxConcurrentOrders : "N/A";
            console.log(`[Matching] [DEBUG] - ${v.name}: Avail=${avail}, Active=${active}, Max=${max}, Dist=${v.distance.toFixed(0)}m, HasGeo=${!!v.geo}`);
        });

        if (matchingVolunteers.length > 0) {
            matchingVolunteers.forEach(v => {
                console.log(`[Matching] - MATCH: ${v.name}, Score: ${Math.round(v.matchScore)}%, Dist: ${v.distance.toFixed(0)}m`);
            });
        }

        if (matchingVolunteers.length === 0) {
            console.log("[Matching] No qualified volunteers found.");
            // Keep status as awaiting_volunteer for some time then fallback
            return;
        }

        // 2. Create Rescue Request notifications
        const notificationPromises = matchingVolunteers.map(v => {
            return Notification.create({
                userId: v._id,
                type: "rescue_request",
                title: "🚨 Rescue Request",
                message: `Nearby rescue available: ${listing.foodName} (${order.quantityOrdered} items). Your match score: ${Math.round(v.matchScore)}%`,
                data: {
                    orderId: order._id,
                    listingId: listing._id,
                    distance: `${(v.distance / 1000).toFixed(1)}km`,
                    action: "view_rescue"
                }
            });
        });

        await Promise.all(notificationPromises);
        console.log(`[Matching] Notified ${matchingVolunteers.length} high-match volunteers`);

        // 3. Fallback timeout
        setTimeout(async () => {
            const updatedOrder = await Order.findById(order._id);
            if (updatedOrder && updatedOrder.status === "awaiting_volunteer") {
                console.log(`[Matching] No volunteer accepted order ${order._id} after 1 min. Falling back.`);

                updatedOrder.status = "placed";
                updatedOrder.fulfillment = "self_pickup";
                await updatedOrder.save();

                await Notification.create({
                    userId: order.buyerId,
                    type: "order_update",
                    title: "🚚 Delivery Update",
                    message: "No volunteer available right now. Please arrange for self-pickup.",
                    data: { orderId: order._id }
                });
            }
        }, 60000); // 1 minute

    } catch (error) {
        console.error("[Matching] Error in initiateVolunteerMatching:", error);
    }
}
// 11. Verify OTP and transition status
exports.verifyOtp = async (req, res) => {
    try {
        const { id } = req.params;
        const { otp } = req.body;

        const order = await Order.findById(id).populate('listingId', 'foodName');
        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        let isCorrect = false;
        let nextStatus = null;

        if (order.fulfillment === "self_pickup") {
            // Only one stage: Handover to Buyer
            if (otp === order.handoverOtp) {
                isCorrect = true;
                nextStatus = "delivered";
            }
        } else {
            // Volunteer Delivery has two stages
            // Stage 1: Handover from Seller to Volunteer
            if (["placed", "volunteer_assigned", "awaiting_volunteer"].includes(order.status)) {
                if (otp === order.pickupOtp) {
                    isCorrect = true;
                    // In volunteer delivery, after seller verifies pickupOtp, it's picked_up
                    nextStatus = "picked_up";
                }
            }
            // Stage 2: Handover from Volunteer to Buyer
            else if (["picked_up", "in_transit"].includes(order.status)) {
                if (otp === order.handoverOtp) {
                    isCorrect = true;
                    nextStatus = "delivered";
                }
            }
        }

        if (!isCorrect) {
            return res.status(400).json({ error: "Invalid OTP code" });
        }

        // Apply transition
        order.status = nextStatus;
        if (nextStatus === "picked_up") order.timeline.pickedUpAt = new Date();
        if (nextStatus === "delivered") {
            order.timeline.deliveredAt = new Date();

            // If volunteer delivery, decrement activeOrders and ADD TRUST SCORE BONUS
            if (order.volunteerId && order.fulfillment === "volunteer_delivery") {
                await VolunteerProfile.findOneAndUpdate(
                    { userId: order.volunteerId },
                    {
                        $inc: { "availability.activeOrders": -1 },
                        $set: { "availability.isAvailable": true } // Re-enable availability
                    }
                );

                // Add Trust Score Bonus (+2) to User model
                await User.findByIdAndUpdate(
                    order.volunteerId,
                    { $inc: { trustScore: 2 } }
                );

                // Ensure Trust Score doesn't exceed 100
                await User.findOneAndUpdate(
                    { _id: order.volunteerId, trustScore: { $gt: 100 } },
                    { $set: { trustScore: 100 } }
                );
            }
        }

        await order.save();

        // Send Notifications
        if (nextStatus === "picked_up") {
            await Notification.create([
                {
                    userId: order.buyerId,
                    type: "order_update",
                    title: "🚚 Food Picked Up!",
                    message: "The volunteer has collected your food and is on the way.",
                    data: { orderId: order._id }
                },
                {
                    userId: order.volunteerId,
                    type: "order_update",
                    title: "🚚 Delivery Assignment",
                    message: `Food collected! Now deliver ${order.quantityOrdered}x ${order.listingId?.foodName || 'food items'} to the buyer.`,
                    data: { 
                        orderId: order._id, 
                        status: "picked_up",
                        action: "deliver_to_buyer"
                    }
                }
            ], { ordered: true });
        } else if (nextStatus === "delivered") {
            // Notify both Buyer and Seller
            await Notification.create([
                {
                    userId: order.buyerId,
                    type: "order_update",
                    title: "✅ Delivered!",
                    message: "Hope you enjoy the food! This rescue is complete.",
                    data: { orderId: order._id }
                },
                {
                    userId: order.sellerId,
                    type: "order_update",
                    title: "✅ Rescue Successful!",
                    message: "Your food donation has been successfully delivered.",
                    data: { orderId: order._id }
                }
            ], { ordered: true });
        }

        res.status(200).json({
            message: `OTP verified. Status updated to ${nextStatus}`,
            order
        });

    } catch (error) {
        console.error("Verify OTP Error:", error);
        res.status(500).json({ error: error.message });
    }
};
