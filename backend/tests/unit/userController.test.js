const userController = require('../../controllers/userController');
const User = require('../../models/User');
const httpMocks = require('node-mocks-http');

jest.mock('../../models/User');

describe('User Controller - createUser', () => {
    let req, res, next;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        next = jest.fn();
    });

    it('should return 400 if firebaseUid is missing', async () => {
        req.body = {
            firebaseUID: {}
        };

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData()).toEqual({
            error: "firebaseUID is required"
        });
    });

    it('should return 200 if user already exists', async () => {
        req.body = {
            firebaseUID: {
                firebaseUid: 'existing-uid',
                name: 'Test User'
            }
        };

        User.findOne.mockResolvedValue({
            firebaseUid: 'existing-uid',
            name: 'Test User'
        });

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().message).toBe("User already exists");
    });

    it('should create a new user if not exists', async () => {
        req.body = {
            firebaseUID: {
                firebaseUid: 'new-uid',
                name: 'New User'
            }
        };

        User.findOne.mockResolvedValue(null);
        User.create.mockResolvedValue({
            firebaseUid: 'new-uid',
            name: 'New User'
        });

        await userController.createUser(req, res);

        expect(res.statusCode).toBe(201);
        expect(res._getJSONData().message).toBe("User created successfully");
        expect(User.create).toHaveBeenCalled();
    });
});
