const Review = require("../models/Review");
const Order = require("../models/Order");
const SellerProfile = require("../models/SellerProfile");
const VolunteerProfile = require("../models/VolunteerProfile");
const mongoose = require("mongoose");

exports.createReview = async (req, res) => {
    try {
        const { orderId, reviewerId, targetType, targetUserId, rating, comment, tags } = req.body;

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        const review = new Review({
            orderId,
            reviewerId,
            targetType,
            targetUserId,
            rating,
            comment,
            tags
        });

        await review.save();

        // Update target profile stats
        if (targetType === "volunteer") {
            const profile = await VolunteerProfile.findOne({ userId: targetUserId });
            if (profile) {
                const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) + rating;
                profile.stats.ratingCount += 1;
                profile.stats.avgRating = totalRating / profile.stats.ratingCount;
                await profile.save();
            }
        } else if (targetType === "seller") {
            const profile = await SellerProfile.findOne({ userId: targetUserId });
            if (profile) {
                const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) + rating;
                profile.stats.ratingCount += 1;
                profile.stats.avgRating = totalRating / profile.stats.ratingCount;
                await profile.save();
            }
        }

        res.status(201).json({ message: "Review submitted successfully", review });

    } catch (error) {
        console.error("Create Review Error:", error);
        res.status(500).json({ error: error.message });
    }
};

exports.getReviewsByTarget = async (req, res) => {
    try {
        const { targetUserId } = req.params;
        const reviews = await Review.find({ targetUserId })
            .populate("reviewerId", "name profilePictureUrl")
            .sort({ createdAt: -1 });

        res.status(200).json(reviews);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
