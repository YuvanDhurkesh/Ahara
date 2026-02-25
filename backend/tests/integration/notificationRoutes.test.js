const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const Notification = require('../../models/Notification');
const { connect, disconnect } = require('../setup');
const mongoose = require('mongoose');

describe('Notification Routes Integration Tests', () => {
    let user;
    let userId;

    beforeAll(async () => {
        await connect();
    }, 60000);

    afterAll(async () => {
        await disconnect();
    }, 60000);

    beforeEach(async () => {
        await User.deleteMany({});
        await Notification.deleteMany({});

        // Create a test user
        user = await User.create({
            firebaseUid: 'test-user-uid',
            name: 'Test Notif User',
            email: 'notif@test.com',
            role: 'buyer',
            phone: '1234567890'
        });
        userId = user._id.toString();
    });

    it('GET /api/notifications/user/:userId should get user notifications', async () => {
        // Create some notifications
        await Notification.create([
            { userId, type: 'info', title: 'Notif 1', message: 'Message 1' },
            { userId, type: 'info', title: 'Notif 2', message: 'Message 2' }
        ]);

        const res = await request(app).get(`/api/notifications/user/${userId}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.notifications.length).toBe(2);
        expect(res.body.pagination.totalNotifications).toBe(2);
    });

    it('GET /api/notifications/user/:userId/unread-count should get unread count', async () => {
        await Notification.create([
            { userId, type: 'info', title: 'Notif 1', message: 'Message 1', isRead: false },
            { userId, type: 'info', title: 'Notif 2', message: 'Message 2', isRead: true }
        ]);

        const res = await request(app).get(`/api/notifications/user/${userId}/unread-count`);

        expect(res.statusCode).toBe(200);
        expect(res.body.unreadCount).toBe(1);
    });

    it('PATCH /api/notifications/:id/read should mark notification as read', async () => {
        const notif = await Notification.create({
            userId,
            type: 'info',
            title: 'Unread Notif',
            message: 'Read me'
        });

        const res = await request(app)
            .patch(`/api/notifications/${notif._id}/read`)
            .send({ userId });

        expect(res.statusCode).toBe(200);
        expect(res.body.notification.isRead).toBe(true);
        expect(res.body.notification.readAt).toBeDefined();

        const updatedNotif = await Notification.findById(notif._id);
        expect(updatedNotif.isRead).toBe(true);
    });

    it('PATCH /api/notifications/user/:userId/read-all should mark all as read', async () => {
        await Notification.create([
            { userId, type: 'info', title: 'Notif 1', message: 'Message 1', isRead: false },
            { userId, type: 'info', title: 'Notif 2', message: 'Message 2', isRead: false }
        ]);

        const res = await request(app).patch(`/api/notifications/user/${userId}/read-all`);

        expect(res.statusCode).toBe(200);
        expect(res.body.updatedCount).toBe(2);

        const unreadCount = await Notification.countDocuments({ userId, isRead: false });
        expect(unreadCount).toBe(0);
    });

    it('DELETE /api/notifications/:id should delete a notification', async () => {
        const notif = await Notification.create({
            userId,
            type: 'info',
            title: 'To Delete',
            message: 'Goodbye'
        });

        const res = await request(app)
            .delete(`/api/notifications/${notif._id}`)
            .send({ userId });

        expect(res.statusCode).toBe(200);

        const deletedNotif = await Notification.findById(notif._id);
        expect(deletedNotif).toBeNull();
    });
});
