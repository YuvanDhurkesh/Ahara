const Order = require("../models/Order");
const Listing = require("../models/Listing");
const mongoose = require("mongoose");

// Create a new order
exports.createOrder = async (req, res) => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
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
        const newOrder = new Order({
            listingId,
            sellerId: listing.sellerId,
            buyerId,
            quantityOrdered,
            fulfillment,
            status: "placed",
            pickup,
            drop,
            pricing,
            specialInstructions,
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

        await session.commitTransaction();
        session.endSession();

        res.status(201).json({
            message: "Order placed successfully",
            order: newOrder,
            remainingQuantity: listing.remainingQuantity
        });

    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error("Create Order Error:", error);
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
            .populate('listingId')
            .populate('sellerId', 'email firebaseUid')
            .sort({ createdAt: -1 });

        res.status(200).json(orders);
    } catch (error) {
        console.error("Get Buyer Orders Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Get seller's orders
exports.getSellerOrders = async (req, res) => {
    try {
        const { sellerId } = req.params;
        const { status } = req.query;

        const query = { sellerId };
        if (status) query.status = status;

        const orders = await Order.find(query)
            .populate('listingId')
            .populate('buyerId', 'email firebaseUid')
            .sort({ createdAt: -1 });

        res.status(200).json(orders);
    } catch (error) {
        console.error("Get Seller Orders Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Update order status
exports.updateOrderStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const validStatuses = [
            "placed", "awaiting_volunteer", "volunteer_assigned",
            "volunteer_accepted", "picked_up", "in_transit",
            "delivered", "cancelled", "failed"
        ];

        if (!validStatuses.includes(status)) {
            return res.status(400).json({ error: "Invalid status" });
        }

        const order = await Order.findById(id);
        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        order.status = status;

        // Update timeline
        if (status === "picked_up") order.timeline.pickedUpAt = new Date();
        if (status === "delivered") order.timeline.deliveredAt = new Date();
        if (status === "cancelled") order.timeline.cancelledAt = new Date();

        await order.save();

        res.status(200).json({ message: "Order status updated", order });
    } catch (error) {
        console.error("Update Order Status Error:", error);
        res.status(500).json({ error: error.message });
    }
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
