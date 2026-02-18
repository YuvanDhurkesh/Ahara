const userController = require('../../controllers/userController');
const User = require('../../models/User');
const SellerProfile = require('../../models/SellerProfile');
const BuyerProfile = require('../../models/BuyerProfile');
const httpMocks = require('node-mocks-http');

jest.mock('../../models/User');
jest.mock('../../models/SellerProfile');
jest.mock('../../models/BuyerProfile');

describe('User Controller - createUser', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if firebaseUid is missing', async () => {
        req.body = {
            email: 'test@test.com',
            role: 'buyer'
        };

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toContain('firebaseUid');
    });

    it('should return 400 if email is missing', async () => {
        req.body = {
            firebaseUid: 'test-uid',
            role: 'buyer'
        };

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toContain('email');
    });

    it('should return 400 if role is missing', async () => {
        req.body = {
            firebaseUid: 'test-uid',
            email: 'test@test.com'
        };

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toContain('role');
    });

    it('should return 200 if user already exists', async () => {
        req.body = {
            firebaseUid: 'existing-uid',
            email: 'test@test.com',
            name: 'Test User',
            role: 'buyer'
        };

        const existingUser = {
            _id: '123',
            firebaseUid: 'existing-uid',
            email: 'test@test.com',
            name: 'Test User'
        };

        User.findOne.mockResolvedValue(existingUser);

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(200);
    });

    it('should create a new buyer user successfully', async () => {
        req.body = {
            firebaseUid: 'new-uid',
            email: 'newuser@test.com',
            name: 'New User',
            role: 'buyer',
            phone: '9876543210'
        };

        User.findOne.mockResolvedValue(null);
        User.create.mockResolvedValue({
            _id: '456',
            firebaseUid: 'new-uid',
            email: 'newuser@test.com',
            name: 'New User',
            role: 'buyer'
        });
        BuyerProfile.create.mockResolvedValue({
            userId: '456'
        });

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(201);
        expect(User.create).toHaveBeenCalled();
    });

    it('should create a seller user with profile', async () => {
        req.body = {
            firebaseUid: 'seller-uid',
            email: 'seller@test.com',
            name: 'Seller User',
            role: 'seller',
            phone: '9876543210',
            businessName: 'Food Kitchen'
        };

        User.findOne.mockResolvedValue(null);
        User.create.mockResolvedValue({
            _id: '789',
            firebaseUid: 'seller-uid',
            email: 'seller@test.com',
            role: 'seller',
            trustScore: 50
        });
        SellerProfile.create.mockResolvedValue({
            userId: '789',
            orgName: 'Food Kitchen'
        });

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(201);
        expect(User.create).toHaveBeenCalled();
        expect(SellerProfile.create).toHaveBeenCalled();
    });
});
