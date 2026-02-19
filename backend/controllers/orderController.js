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

        // 6. Notify Seller
        await Notification.create([{
            userId: listing.sellerId,
            type: "order_update",
            title: "📦 New Order Received",
            message: `Someone just ordered ${quantityOrdered}x ${listing.foodName}!`,
            data: {
                orderId: newOrder._id,
                listingId: listing._id,
                action: "view_order"
            }
        }], { session });

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
            .populate('sellerId', 'email firebaseUid')
            .populate('buyerId', 'email firebaseUid')
            .populate('volunteerId', 'email firebaseUid');

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
            .populate("listingId", "foodName foodType images")
            .populate("buyerId", "name phone")
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

        res.status(200).json(notifications);
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

        const order = await Order.findById(id).session(session);

        if (!order) {
            throw new Error("Order not found");
        }

        if (order.status !== "awaiting_volunteer") {
            throw new Error(`Order cannot be accepted (Status: ${order.status})`);
        }

        // Update order status and assign volunteer
        order.status = "volunteer_assigned";
        order.volunteerId = volunteerId;
        order.volunteerAssignedAt = new Date();
        order.timeline.acceptedAt = new Date(); // Using acceptedAt in timeline for volunteer acceptance

        await order.save({ session });

        // Mark relevant notifications as read for ALL volunteers to prevent multiple acceptances
        // (In a real app, you'd only mark it for others if you wanted to hide it)
        // Here we mark it for the specific volunteer who accepted.
        await Notification.updateMany(
            { "data.orderId": id, type: "rescue_request" },
            { isRead: true, readAt: new Date() },
            { session }
        );

        // Notify Buyer
        await Notification.create([{
            userId: order.buyerId,
            type: "order_update",
            title: "🚚 Volunteer Assigned",
            message: "A volunteer has accepted your rescue request and is on the way!",
            data: { orderId: order._id, status: "volunteer_assigned" }
        }], { session });

        // Notify Seller
        await Notification.create([{
            userId: order.sellerId,
            type: "order_update",
            title: "🤝 Volunteer Found",
            message: "A volunteer will arrive shortly to pick up the order.",
            data: { orderId: order._id, status: "volunteer_assigned" }
        }], { session });

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

        // Apply updates
        if (updates.status) {
            order.status = updates.status;
            // Update timeline
            if (updates.status === "picked_up") order.timeline.pickedUpAt = new Date();
            if (updates.status === "delivered") order.timeline.deliveredAt = new Date();
            if (updates.status === "cancelled") order.timeline.cancelledAt = new Date();
            if (updates.status === "placed") order.timeline.placedAt = new Date();
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
async function initiateVolunteerMatching(order, listing) {
    try {
        console.log(`[Matching] Starting search for order ${order._id}`);

        // 1. Get pickup location
        const pickupGeo = listing.pickupGeo;
        if (!pickupGeo || !pickupGeo.coordinates) {
            console.error("[Matching] Listing has no geo coordinates");
            return;
        }

        // 2. Search for active volunteers within 5km
        const volunteers = await User.find({
            role: "volunteer",
            isActive: true,
            geo: {
                $near: {
                    $geometry: pickupGeo,
                    $maxDistance: 5000 // 5km in meters
                }
            }
        }).limit(10); // Notify top 10 nearest

        console.log(`[Matching] Found ${volunteers.length} nearby volunteers`);

        if (volunteers.length === 0) {
            console.log("[Matching] No volunteers found nearby.");
            return;
        }

        // 3. Create Rescue Request notifications
        const notificationPromises = volunteers.map(v => {
            return Notification.create({
                userId: v._id,
                type: "rescue_request",
                title: "🚨 Rescue Request",
                message: `New delivery available: ${listing.foodName} (${order.quantityOrdered} items). Can you help?`,
                data: {
                    orderId: order._id,
                    listingId: listing._id,
                    distance: "Nearby",
                    action: "view_rescue"
                }
            });
        });

        await Promise.all(notificationPromises);
        console.log(`[Matching] Notified ${volunteers.length} volunteers`);

        // 4. Set fallback timeout (e.g., 30 seconds for demo)
        setTimeout(async () => {
            try {
                const updatedOrder = await Order.findById(order._id);
                if (updatedOrder && updatedOrder.status === "awaiting_volunteer") {
                    console.log(`[Matching] No match found for order ${order._id}. Switching to Self-Pickup.`);

                    updatedOrder.status = "placed";
                    updatedOrder.fulfillment = "self_pickup";
                    await updatedOrder.save();

                    // Notify Buyer
                    await Notification.create({
                        userId: order.buyerId,
                        type: "order_update",
                        title: "🚚 Delivery Update",
                        message: "We couldn't find a volunteer nearby. Please arrange for self-pickup.",
                        data: { orderId: order._id, status: "placed" }
                    });
                }
            } catch (err) {
                console.error("[Matching] Fallback error:", err);
            }
        }, 30000); // 30 seconds

    } catch (error) {
        console.error("[Matching] Error in initiateVolunteerMatching:", error);
    }
}
