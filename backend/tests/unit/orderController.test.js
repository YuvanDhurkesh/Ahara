const orderController = require('../../controllers/orderController');
const Order = require('../../models/Order');
const Listing = require('../../models/Listing');
const Notification = require('../../models/Notification');
const User = require('../../models/User');
const mongoose = require('mongoose');
const httpMocks = require('node-mocks-http');

// Mock all DB models
jest.mock('../../models/Order');
jest.mock('../../models/Listing');
jest.mock('../../models/Notification');
jest.mock('../../models/User');

// ─────────────────────────────────────────────
// Mock mongoose session (transactions)
// ─────────────────────────────────────────────
const mockSession = {
    startTransaction: jest.fn(),
    commitTransaction: jest.fn(),
    abortTransaction: jest.fn(),
    endSession: jest.fn(),
};
jest.spyOn(mongoose, 'startSession').mockResolvedValue(mockSession);

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
const activeListing = () => ({
    _id: 'listing-id-1',
    foodName: 'Fresh Bread',
    sellerId: 'seller-id-1',
    status: 'active',
    remainingQuantity: 10,
    pickupWindow: { to: new Date(Date.now() + 86400000) }, // 24h future
    save: jest.fn().mockResolvedValue(true),
});

// ─────────────────────────────────────────────
// createOrder tests
// ─────────────────────────────────────────────
describe('Order Controller - createOrder', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();

        // Reset session mock behaviour
        mockSession.startTransaction.mockClear();
        mockSession.commitTransaction.mockResolvedValue(undefined);
        mockSession.abortTransaction.mockResolvedValue(undefined);
        mockSession.endSession.mockClear();
    });

    it('should return 400 if listing is not found', async () => {
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(null) });

        req.body = {
            listingId: 'nonexistent',
            buyerId: 'buyer-1',
            quantityOrdered: 2,
            fulfillment: 'self_pickup'
        };

        await orderController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/listing not found/i);
    });

    it('should return 400 if listing is not active', async () => {
        const inactiveListing = { ...activeListing(), status: 'completed', save: jest.fn() };
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(inactiveListing) });

        req.body = {
            listingId: 'listing-id-1',
            buyerId: 'buyer-1',
            quantityOrdered: 2,
            fulfillment: 'self_pickup'
        };

        await orderController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/no longer active/i);
    });

    it('should return 400 if quantity is insufficient', async () => {
        const listing = activeListing();
        listing.remainingQuantity = 1; // Only 1 left
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(listing) });

        req.body = {
            listingId: 'listing-id-1',
            buyerId: 'buyer-1',
            quantityOrdered: 5, // Requesting more than available
            fulfillment: 'self_pickup'
        };

        await orderController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/insufficient quantity/i);
    });

    it('should return 400 if listing has expired', async () => {
        const expiredListing = {
            ...activeListing(),
            pickupWindow: { to: new Date(Date.now() - 1000) }, // 1 second in the past
        };
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(expiredListing) });

        req.body = {
            listingId: 'listing-id-1',
            buyerId: 'buyer-1',
            quantityOrdered: 2,
            fulfillment: 'self_pickup'
        };

        await orderController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/expired/i);
    });

    it('should create an order and return 201 on valid input', async () => {
        const listing = activeListing();
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(listing) });

        const mockOrder = {
            _id: 'order-id-1',
            status: 'placed',
            save: jest.fn().mockResolvedValue(true),
        };
        Order.mockImplementation(() => mockOrder);

        Notification.create.mockResolvedValue([{}]);

        req.body = {
            listingId: 'listing-id-1',
            buyerId: 'buyer-id-1',
            quantityOrdered: 3,
            fulfillment: 'self_pickup',
            pricing: { total: 0 }
        };

        await orderController.createOrder(req, res);

        expect(res.statusCode).toBe(201);
        expect(res._getJSONData().message).toBe('Order placed successfully');
        expect(listing.save).toHaveBeenCalled();
    });

    it('should set status to awaiting_volunteer for volunteer_delivery', async () => {
        const listing = activeListing();
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(listing) });

        let capturedOrderData;
        Order.mockImplementation((data) => {
            capturedOrderData = data;
            return { ...data, save: jest.fn().mockResolvedValue(true) };
        });

        Notification.create.mockResolvedValue([{}]);

        req.body = {
            listingId: 'listing-id-1',
            buyerId: 'buyer-id-1',
            quantityOrdered: 2,
            fulfillment: 'volunteer_delivery'
        };

        await orderController.createOrder(req, res);

        expect(capturedOrderData.status).toBe('awaiting_volunteer');
    });

    it('should set listing status to completed when quantity hits 0', async () => {
        const listing = activeListing();
        listing.remainingQuantity = 5;
        Listing.findById.mockReturnValue({ session: jest.fn().mockResolvedValue(listing) });

        Order.mockImplementation(() => ({
            save: jest.fn().mockResolvedValue(true)
        }));
        Notification.create.mockResolvedValue([{}]);

        req.body = {
            listingId: 'listing-id-1',
            buyerId: 'buyer-id-1',
            quantityOrdered: 5,
            fulfillment: 'self_pickup'
        };

        await orderController.createOrder(req, res);

        expect(listing.status).toBe('completed');
        expect(listing.remainingQuantity).toBe(0);
    });
});

// ─────────────────────────────────────────────
// getOrderById tests
// ─────────────────────────────────────────────
describe('Order Controller - getOrderById', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 404 if order is not found', async () => {
        Order.findById.mockReturnValue({
            populate: jest.fn().mockReturnThis(),
        });
        // Simulate chain ending with null
        const chain = {
            populate: jest.fn().mockReturnThis(),
        };
        chain.populate = jest.fn(() => chain);
        // Make the last populate resolve to null
        let callCount = 0;
        Order.findById.mockReturnValue({
            populate: jest.fn(function () {
                callCount++;
                if (callCount >= 4) return Promise.resolve(null);
                return this;
            })
        });

        req.params = { id: 'nonexistent-order' };
        await orderController.getOrderById(req, res);

        expect(res.statusCode).toBe(404);
        expect(res._getJSONData().error).toMatch(/order not found/i);
    });

    it('should return 200 with the order if found', async () => {
        const mockOrder = { _id: 'order-1', status: 'placed' };
        let callCount = 0;
        Order.findById.mockReturnValue({
            populate: jest.fn(function () {
                callCount++;
                if (callCount >= 4) return Promise.resolve(mockOrder);
                return this;
            })
        });

        req.params = { id: 'order-1' };
        await orderController.getOrderById(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData()._id).toBe('order-1');
    });
});

// ─────────────────────────────────────────────
// trust score helper functions
// ─────────────────────────────────────────────

describe('Order Controller - trust score helpers', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('recomputeBuyerTrustScore sets default when no orders', async () => {
        Order.find.mockResolvedValue([]);
        const updateSpy = jest.spyOn(User, 'findByIdAndUpdate').mockResolvedValue({});
        await orderController.recomputeBuyerTrustScore('buyer1');
        expect(updateSpy).toHaveBeenCalledWith('buyer1', { $set: { trustScore: 50 } });
    });

    it('recomputeSellerTrustScore filters terminal orders and applies bonus', async () => {
        const orders = [
            { status: 'delivered' },
            { status: 'cancelled' },
            { status: 'delivered' }
        ];
        Order.find.mockImplementation((query) => {
            expect(query).toEqual({
                sellerId: 'seller1',
                status: { $in: ['delivered', 'cancelled'] }
            });
            return Promise.resolve(orders);
        });
        const updateSpy = jest.spyOn(User, 'findByIdAndUpdate').mockResolvedValue({});
        await orderController.recomputeSellerTrustScore('seller1');
        // 2 completed, 1 cancelled, onTimeRate=1 => base=80, plus bonus 2*2=4 => 84
        expect(updateSpy).toHaveBeenCalledWith('seller1', { $set: { trustScore: 84 } });
    });

    it('recomputeVolunteerTrustScore filters terminal orders and applies bonus', async () => {
        const orders = [
            { status: 'delivered' },
            { status: 'cancelled', cancellation: { cancelledBy: 'volunteer' } },
        ];
        Order.find.mockImplementation((query) => {
            expect(query).toEqual({
                volunteerId: 'vol1',
                status: { $in: ['delivered', 'cancelled'] }
            });
            return Promise.resolve(orders);
        });
        const updateSpy = jest.spyOn(User, 'findByIdAndUpdate').mockResolvedValue({});
        await orderController.recomputeVolunteerTrustScore('vol1');
        // base formula => 70, plus 2*completed (1) = 72
        expect(updateSpy).toHaveBeenCalledWith('vol1', { $set: { trustScore: 72 } });
    });
});
