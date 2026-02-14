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
