jest.mock('twilio', () => {
    return jest.fn().mockReturnValue({
        messages: {
            create: jest.fn().mockResolvedValue({ sid: 'mock-sid' })
        }
    });
});

const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const Otp = require('../../models/Otp');
const { connect, disconnect } = require('../setup');

describe('OTP Routes Integration Tests', () => {
    const phoneNumber = '9876543210';

    beforeAll(async () => {
        await connect();
    }, 60000);

    afterAll(async () => {
        await disconnect();
    }, 60000);

    beforeEach(async () => {
        await User.deleteMany({});
        await Otp.deleteMany({});
    });

    it('POST /api/otp/send should send OTP', async () => {
        const res = await request(app)
            .post('/api/otp/send')
            .send({ phoneNumber });

        expect(res.statusCode).toBe(200);
        expect(res.body.message).toContain('successfully');
        expect(res.body.phoneNumber).toBe(phoneNumber);

        // If Twilio is not configured, it returns OTP in response
        if (res.body.otp) {
            expect(res.body.otp).toHaveLength(6);
        }

        // Verify in DB
        const otpRecord = await Otp.findOne({ phoneNumber });
        expect(otpRecord).toBeTruthy();
        expect(otpRecord.otp).toHaveLength(6);
    });

    it('POST /api/otp/verify should verify valid OTP', async () => {
        // Create manual OTP
        const otpCode = '123456';
        await Otp.create({
            phoneNumber,
            otp: otpCode,
            expiresAt: new Date(Date.now() + 5 * 60 * 1000)
        });

        const res = await request(app)
            .post('/api/otp/verify')
            .send({ phoneNumber, otp: otpCode });

        expect(res.statusCode).toBe(200);
        expect(res.body.message).toContain('verified');
        expect(res.body.isExistingUser).toBe(false);

        // Verify OTP is deleted after use
        const otpRecord = await Otp.findOne({ phoneNumber });
        expect(otpRecord).toBeNull();
    });

    it('POST /api/otp/verify should fail with invalid OTP', async () => {
        await Otp.create({
            phoneNumber,
            otp: '111111',
            expiresAt: new Date(Date.now() + 5 * 60 * 1000)
        });

        const res = await request(app)
            .post('/api/otp/verify')
            .send({ phoneNumber, otp: '222222' });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toContain('Invalid');
    });

    it('POST /api/otp/verify should mark existing user as verified', async () => {
        // Create user
        await User.create({
            firebaseUid: 'test-user-uid',
            name: 'Test OTP User',
            email: 'otp@test.com',
            role: 'buyer',
            phone: phoneNumber,
            phoneVerified: false
        });

        const otpCode = '654321';
        await Otp.create({
            phoneNumber,
            otp: otpCode,
            expiresAt: new Date(Date.now() + 5 * 60 * 1000)
        });

        const res = await request(app)
            .post('/api/otp/verify')
            .send({ phoneNumber, otp: otpCode });

        expect(res.statusCode).toBe(200);
        expect(res.body.isExistingUser).toBe(true);
        expect(res.body.user.phoneVerified).toBe(true);

        const updatedUser = await User.findOne({ phone: phoneNumber });
        expect(updatedUser.phoneVerified).toBe(true);
    });
});
