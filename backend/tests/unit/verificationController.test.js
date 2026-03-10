const verificationController = require('../../controllers/verificationController');
const VolunteerProfile = require('../../models/VolunteerProfile');
const SellerProfile = require('../../models/SellerProfile');
const User = require('../../models/User');
const httpMocks = require('node-mocks-http');

jest.mock('../../models/VolunteerProfile');
jest.mock('../../models/SellerProfile');
jest.mock('../../models/User');
jest.mock('../../utils/aadhaarValidator');

const { validateAadhaar } = require('../../utils/aadhaarValidator');

// ─────────────────────────────────────────────
// verifyAadhaar
// ─────────────────────────────────────────────
describe('Verification Controller - verifyAadhaar', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if phoneNumber is missing', async () => {
        req.body = { aadhaarNumber: '234567890124' };

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Phone number and Aadhaar/);
    });

    it('should return 400 if aadhaarNumber is missing', async () => {
        req.body = { phoneNumber: '9876543210' };

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Phone number and Aadhaar/);
    });

    it('should return 400 if aadhaar validation fails', async () => {
        req.body = { phoneNumber: '9876543210', aadhaarNumber: '000000000000' };
        validateAadhaar.mockReturnValue({ isValid: false, error: 'Aadhaar must start with 2-9' });

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/must start with 2-9/);
    });

    it('should return 400 if aadhaar ends in 000 (mock failure)', async () => {
        req.body = { phoneNumber: '9876543210', aadhaarNumber: '234567890000' };
        validateAadhaar.mockReturnValue({ isValid: true });

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().success).toBe(false);
    });

    it('should return 200 on successful verification with no existing user', async () => {
        req.body = { phoneNumber: '9876543210', aadhaarNumber: '234567890124' };
        validateAadhaar.mockReturnValue({ isValid: true });
        User.findOne.mockResolvedValue(null);

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().success).toBe(true);
        expect(res._getJSONData().data.status).toBe('verified');
    });

    it('should return 200 and update volunteer profile when user exists', async () => {
        const mockProfile = {
            verification: { idProof: {}, level: 0 },
            save: jest.fn().mockResolvedValue(true),
        };
        const mockUser = { _id: 'user-1', role: 'volunteer', phone: '9876543210' };

        req.body = { phoneNumber: '9876543210', aadhaarNumber: '234567890124' };
        validateAadhaar.mockReturnValue({ isValid: true });
        User.findOne.mockResolvedValue(mockUser);
        VolunteerProfile.findOne.mockResolvedValue(mockProfile);

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(200);
        expect(mockProfile.save).toHaveBeenCalled();
        expect(mockProfile.verification.idProof.verified).toBe(true);
    });

    it('should return 200 and update seller profile when seller user exists', async () => {
        const mockProfile = {
            fssai: { verified: false },
            save: jest.fn().mockResolvedValue(true),
        };
        const mockUser = {
            _id: 'user-1',
            role: 'seller',
            phone: '9876543210',
            trustScore: 30,
            save: jest.fn().mockResolvedValue(true),
        };

        req.body = { phoneNumber: '9876543210', aadhaarNumber: '234567890124' };
        validateAadhaar.mockReturnValue({ isValid: true });
        User.findOne.mockResolvedValue(mockUser);
        SellerProfile.findOne.mockResolvedValue(mockProfile);

        await verificationController.verifyAadhaar(req, res);

        expect(res.statusCode).toBe(200);
        expect(mockProfile.fssai.verified).toBe(true);
        expect(mockUser.trustScore).toBe(60);
    });

    it('should return last 4 digits of aadhaar in response', async () => {
        req.body = { phoneNumber: '9876543210', aadhaarNumber: '234567890124' };
        validateAadhaar.mockReturnValue({ isValid: true });
        User.findOne.mockResolvedValue(null);

        await verificationController.verifyAadhaar(req, res);

        expect(res._getJSONData().data.lastFour).toBe('0124');
    });
});
