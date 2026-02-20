const express = require("express");
const router = express.Router();
const notificationController = require("../controllers/notificationController");

// Get notifications for a user
router.get("/user/:userId", notificationController.getUserNotifications);

// Get unread count for a user
router.get("/user/:userId/unread-count", notificationController.getUnreadCount);

// Mark notification as read
router.patch("/:id/read", notificationController.markAsRead);

// Mark all notifications as read for a user
router.patch("/user/:userId/read-all", notificationController.markAllAsRead);

// Delete a notification
router.delete("/:id", notificationController.deleteNotification);

module.exports = router;