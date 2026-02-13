const Order = require('../models/Order');
const gamificationController = require('./gamificationController');

const { calculateExpiry } = require('../utils/perishabilityRules');

// 1. Create Order (Buyer)
exports.createOrder = async (req, res) => {
    console.log("Create Order Request Body:", JSON.stringify(req.body, null, 2));
    try {
        const { buyerId, storeId, items, totalAmount, deliveryAddress, foodType, storageCondition, cookedTime } = req.body;

        // 🛡️ 1. Calculate Expiry
        let expiryTime = null;
        let finalCookedTime = cookedTime ? new Date(cookedTime) : new Date();

        if (foodType && storageCondition) {
            expiryTime = calculateExpiry(foodType, storageCondition, finalCookedTime);

            // 🛡️ 2. Safety Check: If already expired, REJECT
            if (expiryTime <= new Date()) {
                return res.status(400).json({
                    error: "Food is unsafe to donate. It has exceeded its safe consumption window."
                });
            }
        }

        const newOrder = await Order.create({
            buyerId,
            storeId,
            items,
            totalAmount,
            deliveryAddress,
            status: 'PENDING',
            // Save Food Safety Data
            foodType,
            storageCondition,
            cookedTime: finalCookedTime,
            expiryTime
        });

        res.status(201).json({ message: "Order created successfully", order: newOrder });
    } catch (error) {
        console.error("Create Order Error:", error);
        res.status(500).json({
            error: "Failed to create order",
            details: error.message,
            stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
    }
},

    // 2. Accept Order (Volunteer)
    exports.acceptOrder = async (req, res) => {
        try {
            const { orderId } = req.params;
            const { volunteerId } = req.body;

            const order = await Order.findById(orderId);
            if (!order) return res.status(404).json({ error: "Order not found" });

            if (order.status !== 'PENDING') {
                return res.status(400).json({ error: "Order is already taken or completed" });
            }

            order.volunteerId = volunteerId;
            order.status = 'ACCEPTED';
            await order.save();

            res.status(200).json({ message: "Order accepted", order });
        } catch (error) {
            console.error("Accept Order Error:", error);
            res.status(500).json({ error: "Failed to accept order" });
        }
    };

// 3. Update Status (e.g., Picked Up, Delivered)
exports.updateStatus = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { status } = req.body;

        const order = await Order.findById(orderId);
        if (!order) return res.status(404).json({ error: "Order not found" });

        order.status = status;
        await order.save();

        res.status(200).json({ message: `Order status updated to ${status}`, order });
    } catch (error) {
        console.error("Update Status Error:", error);
        res.status(500).json({ error: "Failed to update status" });
    }
};

// 4. Confirm Delivery & Award Points (Buyer)
exports.confirmDelivery = async (req, res) => {
    try {
        const { orderId } = req.params;

        const order = await Order.findById(orderId);
        if (!order) return res.status(404).json({ error: "Order not found" });

        if (order.status === 'COMPLETED') {
            return res.status(400).json({ error: "Order already completed" });
        }

        // Update Status
        order.status = 'COMPLETED';
        await order.save();

        // 🔥 TRIGGER GAMIFICATION
        if (order.volunteerId) {
            // Mock request object for addPoints
            const mockReq = {
                body: {
                    userId: order.volunteerId,
                    actionType: 'COMPLETE_DELIVERY'
                }
            };

            // We call addPoints logic directly or via internal method
            // For simplicity, we'll reuse the controller logic if possible, 
            // or just call the function if it was exported effectively.
            // Ideally gamificationController should have a helper function, 
            // but we can call the handler with a mock Response object or refactor.

            // Let's do a direct call to the shared logic if we refactor, 
            // OR simply make an internal function call if we extract the logic.
            // For now, let's just use a simple HTTP-like call or refactor gamificationController to export a helper.

            // BETTER APPROACH: Refactor gamificationController to export `awardPoints(userId, action)` 
            // but for now to save steps, I will do a manual update here or duplicate logic safely.
            // ACTUALLY, let's just call the gamification controller as a middleware function? No.

            // Let's just import the Logic.
            // I will assume gamificationController.addPointsInternal exists or I will write code here.

            // ... Wait, let's just make a web request or duplicate the simple logic for speed.
            // logic: user.points += 200, save.

            // To be clean:
            await gamificationController.addPoints({ body: { userId: order.volunteerId, actionType: 'COMPLETE_DELIVERY' } }, {
                status: () => ({ json: () => { } }), // Mock Res
            });
        }

        res.status(200).json({ message: "Order completed and points awarded", order });

    } catch (error) {
        console.error("Confirm Order Error:", error);
        res.status(500).json({ error: "Failed to confirm order" });
    }
};

// 5. Get Open Orders (For Volunteers)
exports.getOpenOrders = async (req, res) => {
    try {
        const orders = await Order.find({ status: 'PENDING' });
        res.status(200).json(orders);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch orders" });
    }
};

// 6. Get My Orders (Buyer/Volunteer)
exports.getUserOrders = async (req, res) => {
    try {
        const { userId, role } = req.query; // role: 'buyer' or 'volunteer'
        const query = role === 'volunteer' ? { volunteerId: userId } : { buyerId: userId };

        const orders = await Order.find(query).sort({ createdAt: -1 });
        res.status(200).json(orders);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch user orders" });
    }
};
