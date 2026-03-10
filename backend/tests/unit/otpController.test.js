const otpController = require('../../controllers/otpController');
const Otp = require('../../models/Otp');
const User = require('../../models/User');
const httpMocks = require('node-mocks-http');

jest.mock('../../models/Otp');
jest.mock('../../models/User');
jest.mock('../../models/BuyerProfile');
jest.mock('../../models/SellerProfile');
jest.mock('../../models/VolunteerProfile');

// ─────────────────────────────────────────────
// sendOtp
// ─────────────────────────────────────────────
describe('OTP Controller - sendOtp', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if phoneNumber is missing', async () => {
        req.body = {};

        await otpController.sendOtp(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Phone number is required/);
    });

    it('should send OTP successfully and return 200', async () => {
        req.body = { phoneNumber: '9876543210' };
        Otp.findOneAndUpdate.mockResolvedValue({ phoneNumber: '9876543210', otp: '123456' });

        await otpController.sendOtp(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().message).toMatch(/OTP sent/i);
        expect(res._getJSONData().phoneNumber).toBe('9876543210');
    });

    it('should include otp in response when Twilio is not configured', async () => {
        req.body = { phoneNumber: '9876543210' };
        Otp.findOneAndUpdate.mockResolvedValue({ phoneNumber: '9876543210', otp: '654321' });

        await otpController.sendOtp(req, res);

        expect(res.statusCode).toBe(200);
        // In test environment, Twilio is not configured, so OTP should be in response
        expect(res._getJSONData().otp).toBeDefined();
    });

    it('should handle database errors gracefully', async () => {
        req.body = { phoneNumber: '9876543210' };
        Otp.findOneAndUpdate.mockRejectedValue(new Error('DB connection failed'));

        await otpController.sendOtp(req, res);

        expect(res.statusCode).toBe(500);
    });
});

// ─────────────────────────────────────────────
// verifyOtp
// ─────────────────────────────────────────────
describe('OTP Controller - verifyOtp', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if phoneNumber is missing', async () => {
        req.body = { otp: '123456' };

        await otpController.verifyOtp(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Phone number and OTP are required/);
    });

    it('should return 400 if otp is missing', async () => {
        req.body = { phoneNumber: '9876543210' };

        await otpController.verifyOtp(req, res);

        expect(res.statusCode).toBe(400);
    });

    it('should return 400 if OTP record is not found', async () => {
        req.body = { phoneNumber: '9876543210', otp: '123456' };
        Otp.findOne.mockResolvedValue(null);

        await otpController.verifyOtp(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/not found or expired/);
    });

    it('should return 400 if OTP does not match', async () => {
        req.body = { phoneNumber: '9876543210', otp: '999999' };
        Otp.findOne.mockResolvedValue({ phoneNumber: '9876543210', otp: '123456' });

        await otpController.verifyOtp(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Invalid verification code/);
    });

    it('should return 200 on successful OTP verification (new user)', async () => {
        req.body = { phoneNumber: '9876543210', otp: '123456' };
        Otp.findOne.mockResolvedValue({ _id: 'otp-1', phoneNumber: '9876543210', otp: '123456' });
        User.findOne.mockResolvedValue(null);
        Otp.deleteOne.mockResolvedValue({});

        await otpController.verifyOtp(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().message).toMatch(/verified successfully/);
        expect(res._getJSONData().isExistingUser).toBe(false);
    });

    it('should return 200 and mark existing user phone as verified', async () => {
        const mockUser = {
            _id: 'user-1',
            role: 'buyer',
            phoneVerified: false,
            save: jest.fn().mockResolvedValue(true),
        };
        req.body = { phoneNumber: '9876543210', otp: '123456' };
        Otp.findOne.mockResolvedValue({ _id: 'otp-1', phoneNumber: '9876543210', otp: '123456' });
        User.findOne.mockResolvedValue(mockUser);
        Otp.deleteOne.mockResolvedValue({});

        // Mock the BuyerProfile require inside verifyOtp
        const BuyerProfile = require('../../models/BuyerProfile');
        BuyerProfile.findOne = jest.fn().mockResolvedValue({ userId: 'user-1' });

        await otpController.verifyOtp(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().isExistingUser).toBe(true);
        expect(mockUser.phoneVerified).toBe(true);
        expect(mockUser.save).toHaveBeenCalled();
    });

    it('should delete OTP after successful verification', async () => {
        req.body = { phoneNumber: '9876543210', otp: '123456' };
        Otp.findOne.mockResolvedValue({ _id: 'otp-1', phoneNumber: '9876543210', otp: '123456' });
        User.findOne.mockResolvedValue(null);
        Otp.deleteOne.mockResolvedValue({});

        await otpController.verifyOtp(req, res);

        expect(Otp.deleteOne).toHaveBeenCalledWith({ _id: 'otp-1' });
    });
});
