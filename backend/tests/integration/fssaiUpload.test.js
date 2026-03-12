const request = require('supertest');
const mongoose = require('mongoose');
const path = require('path');
const fs = require('fs');

// Mock tesseract.js
jest.mock('tesseract.js', () => ({
    createWorker: jest.fn().mockResolvedValue({
        recognize: jest.fn().mockResolvedValue({
            data: { text: 'FSSAI Licence Number 12345678901234 Food Safety Standards Authority' },
        }),
        terminate: jest.fn(),
    }),
}));

// Mock cloudinary
jest.mock('cloudinary', () => ({
    v2: {
        config: jest.fn(),
        uploader: {
            upload_stream: jest.fn((options, callback) => {
                const stream = require('stream');
                const writable = new stream.Writable({
                    write(chunk, encoding, next) { next(); },
                });
                writable.on('finish', () => {
                    callback(null, { secure_url: 'https://res.cloudinary.com/test/fssai_cert.jpg' });
                });
                return writable;
            }),
        },
    },
}));

// We need to setup the database connection before importing models
const { setupDB } = require('../setup');
setupDB();

const User = require('../../models/User');
const SellerProfile = require('../../models/SellerProfile');

// Import the app (or create a mini express app for testing)
const express = require('express');
const fssaiController = require('../../controllers/fssaiController');

const app = express();
app.use(express.json());
app.post(
    '/api/users/seller/fssai/:uid',
    fssaiController.uploadMiddleware,
    fssaiController.verifyFssaiCertificate
);

describe('FSSAI Certificate Upload', () => {
    let testUser;
    let testProfile;

    beforeEach(async () => {
        // Create a test seller user
        testUser = await User.create({
            firebaseUid: 'test-seller-uid-123',
            name: 'Test Restaurant',
            email: 'test@restaurant.com',
            phone: '9876543210',
            role: 'seller',
        });

        testProfile = await SellerProfile.create({
            userId: testUser._id,
            orgName: 'Test Restaurant',
            orgType: 'restaurant',
        });
    });

    afterEach(async () => {
        await User.deleteMany({});
        await SellerProfile.deleteMany({});
    });

    it('should return 400 if fssaiNumber is not 14 digits', async () => {
        const res = await request(app)
            .post('/api/users/seller/fssai/test-seller-uid-123')
            .field('fssaiNumber', '12345')
            .attach('certificate', Buffer.from('fake-image'), 'cert.jpg');

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('14 digits');
    });

    it('should return 400 if no file is uploaded', async () => {
        const res = await request(app)
            .post('/api/users/seller/fssai/test-seller-uid-123')
            .send({ fssaiNumber: '12345678901234' });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('No certificate');
    });

    it('should return 200 and set verified=true when OCR detects valid certificate', async () => {
        const res = await request(app)
            .post('/api/users/seller/fssai/test-seller-uid-123')
            .field('fssaiNumber', '12345678901234')
            .attach('certificate', Buffer.from('fake-image-data'), 'fssai_cert.jpg');

        expect(res.statusCode).toBe(200);
        expect(res.body.message).toContain('verified');
        expect(res.body.fssai.verified).toBe(true);
        expect(res.body.fssai.number).toBe('12345678901234');
    });

    it('should return 404 for non-existent user', async () => {
        const res = await request(app)
            .post('/api/users/seller/fssai/non-existent-uid')
            .field('fssaiNumber', '12345678901234')
            .attach('certificate', Buffer.from('fake-image-data'), 'cert.jpg');

        expect(res.statusCode).toBe(404);
    });
});
