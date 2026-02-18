const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const BuyerProfile = require('../../models/BuyerProfile');
const { connect, disconnect } = require('../setup');

describe('User Routes Integration Tests', () => {
    // Timeout: 60 seconds (from jest.config.js)
    
    beforeAll(async () => {
        await connect();
    });

    afterAll(async () => {
        await disconnect();
    });

    beforeEach(async () => {
        try {
            await User.deleteMany({});
            await BuyerProfile.deleteMany({});
        } catch (e) {
            console.error('Cleanup error:', e.message);
        }
    });

    it('POST /api/users/create should create a new user', async () => {
        const res = await request(app)
            .post('/api/users/create')
            .send({
                firebaseUid: 'test-uid-123',
                name: 'Integration User',
                email: 'integration@test.com',
                role: 'buyer',
                phone: '9876543210'
            });

        expect(res.statusCode).toBe(201);
        expect(res.body.user).toBeDefined();
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
            role: 'buyer',
            phone: '9876543210'
        });

        const res = await request(app)
            .post('/api/users/create')
            .send({
                firebaseUid: 'duplicate-uid',
                name: 'Duplicate Attempt',
                email: 'original@test.com',
                role: 'buyer',
                phone: '9876543210'
            });

        expect(res.statusCode).toBe(200);

        // Verify name wasn't updated
        const user = await User.findOne({ firebaseUid: 'duplicate-uid' });
        expect(user.name).toBe('Original User');
    });

    it('POST /api/users/create should fail without firebaseUid', async () => {
        const res = await request(app)
            .post('/api/users/create')
            .send({
                email: 'test@test.com',
                role: 'buyer'
                // Missing firebaseUid
            });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('firebaseUid');
    });

    it('POST /api/users/create should fail without email', async () => {
        const res = await request(app)
            .post('/api/users/create')
            .send({
                firebaseUid: 'test-uid',
                role: 'buyer'
                // Missing email
            });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('email');
    });

    it('POST /api/users/create should fail without role', async () => {
        const res = await request(app)
            .post('/api/users/create')
            .send({
                firebaseUid: 'test-uid',
                email: 'test@test.com'
                // Missing role
            });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('role');
    });
});
