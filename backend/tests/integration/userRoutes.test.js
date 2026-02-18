const request = require('supertest');
const app = require('../../server');
const mongoose = require('mongoose');
const User = require('../../models/User');

describe('User Routes Integration Tests', () => {

    // Clear database before each test
    beforeEach(async () => {
        await User.deleteMany({});
    });

    it('POST /api/users/create should create a new user', async () => {
        const res = await request(app)
            .post('/api/users/create')
            .send({
                firebaseUid: 'test-uid-123',
                name: 'Integration User',
                email: 'integration@test.com',
                phone: '1234567890',
                role: 'buyer'
            });

        expect(res.statusCode).toBe(201);
        expect(res.body.message).toBe('User and profile created successfully');
        expect(res.body.user.firebaseUid).toBe('test-uid-123');

        // Verify in DB
        const user = await User.findOne({ firebaseUid: 'test-uid-123' });
        expect(user).toBeTruthy();
        expect(user.name).toBe('Integration User');
    });

    it('POST /api/users/create should return existing user if duplicate', async () => {
        // Create initial user
        await User.create({
            firebaseUid: 'duplicate-uid',
            name: 'Original User',
            email: 'original@test.com',
            phone: '0987654321',
            role: 'buyer'
        });

        const res = await request(app)
            .post('/api/users/create')
            .send({
                firebaseUid: 'duplicate-uid',
                name: 'Duplicate Attempt',
                email: 'duplicate@test.com',
                phone: '1122334455',
                role: 'buyer'
            });

        expect(res.statusCode).toBe(200);
        expect(res.body.message).toBe('User already exists');
        expect(res.body.user.firebaseUid).toBe('duplicate-uid');

        // Ensure name wasn't updated
        const user = await User.findOne({ firebaseUid: 'duplicate-uid' });
        expect(user.name).toBe('Original User');
    });

    it('POST /api/users/create shoud fail without firebaseUid', async () => {
        const res = await request(app)
            .post('/api/users/create')
            .send({
                // Missing firebaseUid
                name: 'No UID User',
                role: 'buyer'
            });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('firebaseUid, email, and role are required');
    });
});
