const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../server'); // Adjust path to server.js
const User = require('../../models/User');

// Database connection is handled by setup.js and server.js logic

describe('Gamification & Trust Score API', () => {
    let userId;

    beforeEach(async () => {
        // Create a test user
        const res = await request(app).post('/api/users/create').send({
            firebaseUID: {
                firebaseUid: 'game-user-123',
                name: 'Gamer One',
                email: 'gamer@test.com',
                role: 'Volunteer'
            }
        });
        if (res.statusCode !== 201) {
            console.error("Setup User Creation Failed:", res.statusCode, res.body);
        }
        userId = 'game-user-123';
    });

    afterEach(async () => {
        await User.deleteMany({});
    });

    test('should add points and update level', async () => {
        const res = await request(app).post('/api/users/points/add').send({
            userId: userId,
            actionType: 'COMPLETE_DELIVERY' // +200 points
        });

        expect(res.statusCode).toBe(200);
        expect(res.body.points).toBe(200);
        expect(res.body.level).toBe(1);
    });

    test('should calculate trust score correctly', async () => {
        // First, give some points to affect performance score
        await request(app).post('/api/users/points/add').send({
            userId: userId,
            actionType: 'COMPLETE_DELIVERY'
        }); // 200 pts -> 4 perf pts

        const res = await request(app).post('/api/users/trust/update').send({
            userId: userId,
            verificationStats: { isIdVerified: true }, // +20
            performanceStats: { reliabilityRate: 0.96 }, // +10
            feedbackStats: { averageRating: 4.5 } // (4.5/5)*20 = 18
        });

        // Expected: 
        // Verification: 0 (phone) + 20 (id) + 0 (loc) = 20
        // Performance: 4 (points) + 10 (reliability) = 14
        // Feedback: 18
        // Total: 52

        expect(res.statusCode).toBe(200);
        expect(res.body.trustScore).toBeGreaterThan(50);
    });
});
