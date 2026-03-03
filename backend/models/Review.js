const mongoose = require("mongoose");

const reviewResponseSchema = new mongoose.Schema(
    {
        reviewId: { type: mongoose.Schema.Types.ObjectId, ref: "Review", required: true, unique: true },
        responderId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        message: { type: String, required: true, maxlength: 500 },
    },
    { timestamps: true }
);

const reviewSchema = new mongoose.Schema(
    {
        orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order", required: true, index: true },
        reviewerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        reviewerName: String, // Cached for efficiency

        targetType: { type: String, enum: ["seller", "volunteer"], required: true },
        targetUserId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },

        rating: { type: Number, min: 1, max: 5, required: true },
        comment: { type: String, maxlength: 500 },
        tags: [String],
        
        isAnonymous: { type: Boolean, default: false },
        isVerified: { type: Boolean, default: true }, // Verified purchase
        helpfulCount: { type: Number, default: 0 },
        responseId: { type: mongoose.Schema.Types.ObjectId, ref: "ReviewResponse", default: null }
    },
    { timestamps: true }
);

// Indexes for efficient queries
reviewSchema.index({ targetUserId: 1, createdAt: -1 });
reviewSchema.index({ orderId: 1, targetType: 1 });
reviewSchema.index({ reviewerId: 1, orderId: 1, targetType: 1 }, { unique: true }); // Prevent duplicate reviews

module.exports = {
    Review: mongoose.model("Review", reviewSchema),
    ReviewResponse: mongoose.model("ReviewResponse", reviewResponseSchema)
};
