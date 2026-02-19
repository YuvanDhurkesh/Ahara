const mongoose = require("mongoose");
const { GeoPointSchema } = require("./_shared");

const orderSchema = new mongoose.Schema(
    {
        listingId: { type: mongoose.Schema.Types.ObjectId, ref: "Listing", required: true, index: true },
        sellerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        buyerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        quantityOrdered: { type: Number, required: true },

        fulfillment: { type: String, enum: ["self_pickup", "volunteer_delivery"], required: true },

        volunteerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null, index: true },
        volunteerAssignedAt: Date,

        status: {
            type: String,
            enum: [
                "placed",
                "awaiting_volunteer",
                "volunteer_assigned",
                "volunteer_accepted",
                "picked_up",
                "in_transit",
                "delivered",
                "cancelled",
                "failed"
            ],
            default: "placed",
            index: true
        },

        pickup: {
            geo: {
                type: { type: String, enum: ["Point"] },
                coordinates: { type: [Number] }
            },
            addressText: String,
            scheduledAt: Date
        },

        drop: {
            geo: {
                type: { type: String, enum: ["Point"] },
                coordinates: { type: [Number] }
            },
            addressText: String
        },

        tracking: {
            lastVolunteerGeo: {
                type: { type: String, enum: ["Point"] },
                coordinates: { type: [Number] }
            },
            lastUpdatedAt: Date
        },

        pricing: {
            itemTotal: Number,
            deliveryFee: Number,
            platformFee: Number,
            total: Number
        },

        payment: {
            status: { type: String, enum: ["not_required", "pending", "paid", "failed", "refunded"], default: "pending" },
            method: String,
            transactionId: String,
            razorpayOrderId: String,
            razorpayPaymentId: String,
            razorpaySignature: String
        },

        pickupOtp: String,
        handoverOtp: String,

        timeline: {
            placedAt: { type: Date, default: Date.now },
            acceptedAt: Date,
            pickedUpAt: Date,
            deliveredAt: Date,
            cancelledAt: Date
        },

        cancellation: {
            cancelledBy: { type: String, enum: ["buyer", "seller", "volunteer", "system"] },
            reason: String
        },

        specialInstructions: String
    },
    { timestamps: true }
);

orderSchema.index({ buyerId: 1, status: 1 });
orderSchema.index({ sellerId: 1, status: 1 });
orderSchema.index({ volunteerId: 1, status: 1 });

module.exports = mongoose.model("Order", orderSchema);
