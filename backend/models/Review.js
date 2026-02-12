const mongoose = require("mongoose");

const reviewSchema = new mongoose.Schema(
    {
        orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order", required: true, index: true },
        reviewerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

        targetType: { type: String, enum: ["seller", "volunteer"], required: true },
        targetUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },

        rating: { type: Number, min: 1, max: 5, required: true },
        comment: String,
        tags: [String]
    },
    { timestamps: true }
);

reviewSchema.index({ targetUserId: 1, createdAt: -1 });

module.exports = mongoose.model("Review", reviewSchema);
