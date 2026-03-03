const express = require("express");
const router = express.Router();
const reviewController = require("../controllers/reviewController");

// Create a new review
router.post("/", reviewController.createReview);

// Check if order can be reviewed
router.get("/check-reviewable/:orderId", reviewController.checkReviewable);

// Get reviews for a target user (seller/volunteer) with analytics
router.get("/target/:targetUserId", reviewController.getReviewsByTarget);

// Add response to a review
router.post("/:reviewId/response", reviewController.addReviewResponse);

// Update a review
router.put("/:reviewId", reviewController.updateReview);

// Delete a review
router.delete("/:reviewId", reviewController.deleteReview);

module.exports = router;
