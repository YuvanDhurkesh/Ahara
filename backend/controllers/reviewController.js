const { Review, ReviewResponse } = require("../models/Review");
const Order = require("../models/Order");
const User = require("../models/User");
const SellerProfile = require("../models/SellerProfile");
const VolunteerProfile = require("../models/VolunteerProfile");
const mongoose = require("mongoose");

// PREDEFINED TAGS
const SELLER_TAGS = [
    "Quality of food",
    "Packaging quality",
    "Freshness",
    "Meets description",
    "Quick preparation",
    "Value for money"
];

const VOLUNTEER_TAGS = [
    "Delivery speed",
    "Professional behavior",
    "Food condition on arrival",
    "Politeness",
    "Handled with care",
    "On-time delivery"
];

/**
 * Check if an order can be reviewed
 */
exports.checkReviewable = async (req, res) => {
    try {
        const { orderId } = req.params;
        const { buyerId } = req.query;

        const order = await Order.findById(orderId).populate('buyerId sellerId volunteerId');
        
        if (!order) {
            return res.status(404).json({ 
                canReview: false, 
                message: "Order not found" 
            });
        }

        // Check if buyer owns this order
        if (order.buyerId._id.toString() !== buyerId) {
            return res.status(403).json({ 
                canReview: false, 
                message: "Not authorized to review this order" 
            });
        }

        // Check if order is delivered
        if (order.status !== 'delivered') {
            return res.status(400).json({ 
                canReview: false, 
                message: `Order status is '${order.status}', must be 'delivered' to review` 
            });
        }

        // Check if reviews already exist
        const existingSellerReview = await Review.findOne({
            orderId,
            reviewerId: buyerId,
            targetType: 'seller'
        });

        const existingVolunteerReview = order.fulfillment === 'volunteer_delivery'
            ? await Review.findOne({
                orderId,
                reviewerId: buyerId,
                targetType: 'volunteer'
            })
            : null;

        res.status(200).json({
            canReview: true,
            seller: {
                userId: order.sellerId._id,
                name: order.sellerId.name,
                already_reviewed: !!existingSellerReview
            },
            volunteer: order.fulfillment === 'volunteer_delivery' ? {
                userId: order.volunteerId?._id,
                name: order.volunteerId?.name,
                already_reviewed: !!existingVolunteerReview
            } : null,
            order: {
                id: orderId,
                status: order.status,
                fulfillment: order.fulfillment
            }
        });
    } catch (error) {
        console.error("Check Reviewable Error:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Create a new review
 */
exports.createReview = async (req, res) => {
    try {
        const { orderId, reviewerId, targetType, targetUserId, rating, comment, tags, isAnonymous } = req.body;

        // Validation
        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({ error: "Rating must be between 1 and 5" });
        }

        if (comment && (comment.length < 5 || comment.length > 500)) {
            return res.status(400).json({ error: "Comment must be 5-500 characters" });
        }

        if (tags && (!Array.isArray(tags) || tags.length > 3)) {
            return res.status(400).json({ error: "Maximum 3 tags allowed" });
        }

        // Validate tag values
        const validTags = targetType === 'seller' ? SELLER_TAGS : VOLUNTEER_TAGS;
        if (tags && !tags.every(tag => validTags.includes(tag))) {
            return res.status(400).json({ error: `Invalid tags. Valid tags: ${validTags.join(', ')}` });
        }

        const order = await Order.findById(orderId);
        if (!order) {
            return res.status(404).json({ error: "Order not found" });
        }

        // Check order is delivered
        if (order.status !== 'delivered') {
            return res.status(400).json({ error: "Can only review delivered orders" });
        }

        // Check buyer owns order
        if (order.buyerId.toString() !== reviewerId) {
            return res.status(403).json({ error: "Only order buyer can submit reviews" });
        }

        // Prevent duplicate reviews (same reviewer, order, and target)
        const existingReview = await Review.findOne({
            orderId,
            reviewerId,
            targetType,
            targetUserId
        });

        if (existingReview) {
            return res.status(400).json({ error: `You have already reviewed this ${targetType}` });
        }

        // Get reviewer name if not anonymous
        let reviewerName = null;
        if (!isAnonymous) {
            const reviewer = await User.findById(reviewerId, 'name');
            reviewerName = reviewer?.name || 'Verified Buyer';
        }

        const review = new Review({
            orderId,
            reviewerId,
            reviewerName: isAnonymous ? null : reviewerName,
            targetType,
            targetUserId,
            rating,
            comment: comment || null,
            tags: tags || [],
            isAnonymous: isAnonymous || false,
            isVerified: true
        });

        await review.save();

        // Update profile stats
        if (targetType === "volunteer") {
            const profile = await VolunteerProfile.findOne({ userId: targetUserId });
            if (profile) {
                const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) + rating;
                profile.stats.ratingCount += 1;
                profile.stats.avgRating = parseFloat((totalRating / profile.stats.ratingCount).toFixed(2));
                await profile.save();
            }
        } else if (targetType === "seller") {
            const profile = await SellerProfile.findOne({ userId: targetUserId });
            if (profile) {
                const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) + rating;
                profile.stats.ratingCount += 1;
                profile.stats.avgRating = parseFloat((totalRating / profile.stats.ratingCount).toFixed(2));
                await profile.save();
            }
        }

        res.status(201).json({ 
            success: true,
            message: "Review submitted successfully", 
            review 
        });

    } catch (error) {
        console.error("Create Review Error:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Get reviews for a target user (seller/volunteer) with analytics
 */
exports.getReviewsByTarget = async (req, res) => {
    try {
        const { targetUserId } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        // Get total count and paginated reviews
        const [totalReviews, reviews] = await Promise.all([
            Review.countDocuments({ targetUserId }),
            Review.find({ targetUserId })
                .populate("reviewerId", "name profilePictureUrl")
                .populate("responseId")
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
        ]);

        // Calculate analytics
        const allReviews = await Review.find({ targetUserId });
        
        const ratingDistribution = {
            '5': allReviews.filter(r => r.rating === 5).length,
            '4': allReviews.filter(r => r.rating === 4).length,
            '3': allReviews.filter(r => r.rating === 3).length,
            '2': allReviews.filter(r => r.rating === 2).length,
            '1': allReviews.filter(r => r.rating === 1).length,
        };

        const avgRating = allReviews.length > 0 
            ? parseFloat((allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length).toFixed(2))
            : 0;

        const verifiedCount = allReviews.filter(r => r.isVerified).length;
        const verifiedPercentage = allReviews.length > 0 
            ? ((verifiedCount / allReviews.length) * 100).toFixed(0)
            : 0;

        // Tag analytics
        const tagFrequency = {};
        allReviews.forEach(review => {
            review.tags?.forEach(tag => {
                tagFrequency[tag] = (tagFrequency[tag] || 0) + 1;
            });
        });

        // Format reviews for display
        const formattedReviews = reviews.map(review => ({
            _id: review._id,
            rating: review.rating,
            comment: review.comment,
            tags: review.tags,
            reviewer: review.isAnonymous 
                ? { name: "Anonymous Buyer" }
                : { name: review.reviewerName || "Verified Buyer" },
            createdAt: review.createdAt,
            response: review.responseId || null,
            isVerified: review.isVerified
        }));

        res.status(200).json({
            success: true,
            analytics: {
                avgRating,
                totalReviews,
                ratingDistribution,
                verifiedPercentage: `${verifiedPercentage}%`,
                mostCommonTags: Object.entries(tagFrequency)
                    .sort((a, b) => b[1] - a[1])
                    .slice(0, 5)
                    .map(([tag, count]) => ({ tag, count }))
            },
            pagination: {
                page,
                limit,
                totalPages: Math.ceil(totalReviews / limit),
                hasMore: skip + limit < totalReviews
            },
            reviews: formattedReviews
        });
    } catch (error) {
        console.error("Get Reviews Error:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Add response to a review (seller/volunteer reply)
 */
exports.addReviewResponse = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { responderId, message } = req.body;

        if (!message || message.length < 5 || message.length > 500) {
            return res.status(400).json({ error: "Response message must be 5-500 characters" });
        }

        const review = await Review.findById(reviewId);
        if (!review) {
            return res.status(404).json({ error: "Review not found" });
        }

        // Check responder is the target of the review
        if (review.targetUserId.toString() !== responderId) {
            return res.status(403).json({ error: "Only the reviewed user can respond" });
        }

        // Check if response already exists
        if (review.responseId) {
            return res.status(400).json({ error: "This review already has a response" });
        }

        const response = new ReviewResponse({
            reviewId,
            responderId,
            message
        });

        await response.save();

        // Link response to review
        review.responseId = response._id;
        await review.save();

        res.status(201).json({
            success: true,
            message: "Response added successfully",
            response
        });
    } catch (error) {
        console.error("Add Review Response Error:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Update a review (only by reviewer)
 */
exports.updateReview = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { reviewerId, rating, comment, tags } = req.body;

        const review = await Review.findById(reviewId);
        if (!review) {
            return res.status(404).json({ error: "Review not found" });
        }

        // Check if reviewer owns the review
        if (review.reviewerId.toString() !== reviewerId) {
            return res.status(403).json({ error: "Can only update your own reviews" });
        }

        // Validate inputs
        if (rating && (rating < 1 || rating > 5)) {
            return res.status(400).json({ error: "Rating must be between 1 and 5" });
        }

        if (comment && (comment.length < 5 || comment.length > 500)) {
            return res.status(400).json({ error: "Comment must be 5-500 characters" });
        }

        // Calculate rating difference for profile update
        const oldRating = review.rating;
        
        // Update review
        if (rating) review.rating = rating;
        if (comment !== undefined) review.comment = comment;
        if (tags) review.tags = tags;

        await review.save();

        // Update profile stats if rating changed
        if (rating && oldRating !== rating) {
            const ratingDifference = rating - oldRating;
            
            if (review.targetType === "volunteer") {
                const profile = await VolunteerProfile.findOne({ userId: review.targetUserId });
                if (profile) {
                    const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) + ratingDifference;
                    profile.stats.avgRating = parseFloat((totalRating / profile.stats.ratingCount).toFixed(2));
                    await profile.save();
                }
            } else if (review.targetType === "seller") {
                const profile = await SellerProfile.findOne({ userId: review.targetUserId });
                if (profile) {
                    const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) + ratingDifference;
                    profile.stats.avgRating = parseFloat((totalRating / profile.stats.ratingCount).toFixed(2));
                    await profile.save();
                }
            }
        }

        res.status(200).json({
            success: true,
            message: "Review updated successfully",
            review
        });
    } catch (error) {
        console.error("Update Review Error:", error);
        res.status(500).json({ error: error.message });
    }
};

/**
 * Delete a review (only by reviewer)
 */
exports.deleteReview = async (req, res) => {
    try {
        const { reviewId } = req.params;
        const { reviewerId } = req.query;

        const review = await Review.findById(reviewId);
        if (!review) {
            return res.status(404).json({ error: "Review not found" });
        }

        // Check if reviewer owns the review
        if (review.reviewerId.toString() !== reviewerId) {
            return res.status(403).json({ error: "Can only delete your own reviews" });
        }

        const deletedRating = review.rating;
        const targetUserId = review.targetUserId;
        const targetType = review.targetType;

        // Delete response if exists
        if (review.responseId) {
            await ReviewResponse.findByIdAndDelete(review.responseId);
        }

        // Delete review
        await Review.findByIdAndDelete(reviewId);

        // Update profile stats
        if (targetType === "volunteer") {
            const profile = await VolunteerProfile.findOne({ userId: targetUserId });
            if (profile && profile.stats.ratingCount > 0) {
                const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) - deletedRating;
                profile.stats.ratingCount -= 1;
                profile.stats.avgRating = profile.stats.ratingCount > 0 
                    ? parseFloat((totalRating / profile.stats.ratingCount).toFixed(2))
                    : 0;
                await profile.save();
            }
        } else if (targetType === "seller") {
            const profile = await SellerProfile.findOne({ userId: targetUserId });
            if (profile && profile.stats.ratingCount > 0) {
                const totalRating = (profile.stats.avgRating * profile.stats.ratingCount) - deletedRating;
                profile.stats.ratingCount -= 1;
                profile.stats.avgRating = profile.stats.ratingCount > 0 
                    ? parseFloat((totalRating / profile.stats.ratingCount).toFixed(2))
                    : 0;
                await profile.save();
            }
        }

        res.status(200).json({
            success: true,
            message: "Review deleted successfully"
        });
    } catch (error) {
        console.error("Delete Review Error:", error);
        res.status(500).json({ error: error.message });
    }
};
