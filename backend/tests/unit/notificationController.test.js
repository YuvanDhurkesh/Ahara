const notificationController = require('../../controllers/notificationController');
const Notification = require('../../models/Notification');
const httpMocks = require('node-mocks-http');

jest.mock('../../models/Notification');

// ─────────────────────────────────────────────
// getUserNotifications
// ─────────────────────────────────────────────
describe('Notification Controller - getUserNotifications', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return paginated notifications for a user', async () => {
        req.params = { userId: 'user-1' };
        req.query = { page: '1', limit: '20' };

        const mockNotifications = [
            { _id: 'n1', userId: 'user-1', title: 'Order placed', isRead: false },
            { _id: 'n2', userId: 'user-1', title: 'Delivery update', isRead: true },
        ];

        Notification.find.mockReturnValue({
            sort: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                    skip: jest.fn().mockReturnValue({
                        populate: jest.fn().mockResolvedValue(mockNotifications),
                    }),
                }),
            }),
        });
        Notification.countDocuments.mockResolvedValue(2);

        await notificationController.getUserNotifications(req, res);

        expect(res.statusCode).toBe(200);
        const data = res._getJSONData();
        expect(data.notifications).toHaveLength(2);
        expect(data.pagination.totalNotifications).toBe(2);
    });

    it('should filter by isRead when provided', async () => {
        req.params = { userId: 'user-1' };
        req.query = { isRead: 'false' };

        Notification.find.mockReturnValue({
            sort: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                    skip: jest.fn().mockReturnValue({
                        populate: jest.fn().mockResolvedValue([]),
                    }),
                }),
            }),
        });
        Notification.countDocuments.mockResolvedValue(0);

        await notificationController.getUserNotifications(req, res);

        expect(res.statusCode).toBe(200);
        expect(Notification.find).toHaveBeenCalledWith(
            expect.objectContaining({ userId: 'user-1', isRead: false })
        );
    });

    it('should handle errors gracefully', async () => {
        req.params = { userId: 'user-1' };
        req.query = {};

        Notification.find.mockReturnValue({
            sort: jest.fn().mockReturnValue({
                limit: jest.fn().mockReturnValue({
                    skip: jest.fn().mockReturnValue({
                        populate: jest.fn().mockRejectedValue(new Error('DB error')),
                    }),
                }),
            }),
        });

        await notificationController.getUserNotifications(req, res);

        expect(res.statusCode).toBe(500);
    });
});

// ─────────────────────────────────────────────
// markAsRead
// ─────────────────────────────────────────────
describe('Notification Controller - markAsRead', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should mark a notification as read', async () => {
        req.params = { id: 'notif-1' };
        req.body = { userId: 'user-1' };

        Notification.findOneAndUpdate.mockResolvedValue({
            _id: 'notif-1',
            isRead: true,
            readAt: new Date(),
        });

        await notificationController.markAsRead(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().message).toMatch(/marked as read/i);
    });

    it('should return 404 if notification is not found', async () => {
        req.params = { id: 'nonexistent' };
        req.body = { userId: 'user-1' };

        Notification.findOneAndUpdate.mockResolvedValue(null);

        await notificationController.markAsRead(req, res);

        expect(res.statusCode).toBe(404);
    });
});

// ─────────────────────────────────────────────
// markAllAsRead
// ─────────────────────────────────────────────
describe('Notification Controller - markAllAsRead', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should mark all notifications as read for a user', async () => {
        req.params = { userId: 'user-1' };

        Notification.updateMany.mockResolvedValue({ modifiedCount: 5 });

        await notificationController.markAllAsRead(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().updatedCount).toBe(5);
    });

    it('should return 0 updatedCount when no unread notifications exist', async () => {
        req.params = { userId: 'user-1' };

        Notification.updateMany.mockResolvedValue({ modifiedCount: 0 });

        await notificationController.markAllAsRead(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().updatedCount).toBe(0);
    });
});

// ─────────────────────────────────────────────
// getUnreadCount
// ─────────────────────────────────────────────
describe('Notification Controller - getUnreadCount', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return unread notification count', async () => {
        req.params = { userId: 'user-1' };

        Notification.countDocuments.mockResolvedValue(3);

        await notificationController.getUnreadCount(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().unreadCount).toBe(3);
    });

    it('should return 0 when there are no unread notifications', async () => {
        req.params = { userId: 'user-1' };

        Notification.countDocuments.mockResolvedValue(0);

        await notificationController.getUnreadCount(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().unreadCount).toBe(0);
    });
});

// ─────────────────────────────────────────────
// deleteNotification
// ─────────────────────────────────────────────
describe('Notification Controller - deleteNotification', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should delete a notification successfully', async () => {
        req.params = { id: 'notif-1' };
        req.body = { userId: 'user-1' };

        Notification.findOneAndDelete.mockResolvedValue({ _id: 'notif-1' });

        await notificationController.deleteNotification(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().message).toMatch(/deleted/i);
    });

    it('should return 404 if notification is not found', async () => {
        req.params = { id: 'nonexistent' };
        req.body = { userId: 'user-1' };

        Notification.findOneAndDelete.mockResolvedValue(null);

        await notificationController.deleteNotification(req, res);

        expect(res.statusCode).toBe(404);
    });
});
