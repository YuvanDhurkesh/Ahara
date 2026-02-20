const Notification = require("../models/Notification");

// Get notifications for a user
exports.getUserNotifications = async (req, res) => {
    try {
        const { userId } = req.params;
        const { page = 1, limit = 20, isRead } = req.query;

        const query = { userId };
        if (isRead !== undefined) {
            query.isRead = isRead === 'true';
        }

        const notifications = await Notification.find(query)
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit)
            .populate('userId', 'name email');

        const total = await Notification.countDocuments(query);

        res.status(200).json({
            notifications,
            pagination: {
                currentPage: parseInt(page),
                totalPages: Math.ceil(total / limit),
                totalNotifications: total,
                hasNext: page * limit < total,
                hasPrev: page > 1
            }
        });
    } catch (error) {
        console.error("Get User Notifications Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Mark notification as read
exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;

        const notification = await Notification.findOneAndUpdate(
            { _id: id, userId },
            {
                isRead: true,
                readAt: new Date()
            },
            { new: true }
        );

        if (!notification) {
            return res.status(404).json({ error: "Notification not found" });
        }

        res.status(200).json({ message: "Notification marked as read", notification });
    } catch (error) {
        console.error("Mark As Read Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Mark all notifications as read for a user
exports.markAllAsRead = async (req, res) => {
    try {
        const { userId } = req.params;

        const result = await Notification.updateMany(
            { userId, isRead: false },
            {
                isRead: true,
                readAt: new Date()
            }
        );

        res.status(200).json({
            message: "All notifications marked as read",
            updatedCount: result.modifiedCount
        });
    } catch (error) {
        console.error("Mark All As Read Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Get unread count for a user
exports.getUnreadCount = async (req, res) => {
    try {
        const { userId } = req.params;

        const count = await Notification.countDocuments({ userId, isRead: false });

        res.status(200).json({ unreadCount: count });
    } catch (error) {
        console.error("Get Unread Count Error:", error);
        res.status(500).json({ error: error.message });
    }
};

// Delete a notification
exports.deleteNotification = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId } = req.body;

        const notification = await Notification.findOneAndDelete({ _id: id, userId });

        if (!notification) {
            return res.status(404).json({ error: "Notification not found" });
        }

        res.status(200).json({ message: "Notification deleted successfully" });
    } catch (error) {
        console.error("Delete Notification Error:", error);
        res.status(500).json({ error: error.message });
    }
};