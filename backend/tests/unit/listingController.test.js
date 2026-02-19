const listingController = require('../../controllers/listingController');
const Listing = require('../../models/Listing');
const Order = require('../../models/Order');
const SellerProfile = require('../../models/SellerProfile');
const PerishabilityEngine = require('../../utils/perishabilityEngine');
const httpMocks = require('node-mocks-http');

// Mock all DB models and the perishability utility
jest.mock('../../models/Listing');
jest.mock('../../models/Order');
jest.mock('../../models/SellerProfile');
jest.mock('../../utils/perishabilityEngine');

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────
const future = () => new Date(Date.now() + 86400000).toISOString(); // 24h from now
const past = () => new Date(Date.now() - 86400000).toISOString(); // 24h ago

const validBody = () => ({
    sellerId: 'seller-id-123',
    sellerProfileId: 'profile-id-123',
    foodName: 'Fresh Apples',
    totalQuantity: 10,
    foodType: 'fresh_produce',
    category: 'produce',
    dietaryType: 'vegetarian',
    quantityText: '10kg',
    pickupWindow: { from: new Date().toISOString(), to: future() },
    pickupAddressText: '123 Test St',
    pricing: { originalPrice: 100, discountedPrice: 0, isFree: true }
});

// ─────────────────────────────────────────────
// createListing
// ─────────────────────────────────────────────
describe('Listing Controller - createListing', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();

        // Default: safety passes
        PerishabilityEngine.validateSafety.mockReturnValue({
            isValid: true,
            safetyThreshold: '48h'
        });
    });

    it('should return 400 if sellerId is missing', async () => {
        req.body = { ...validBody(), sellerId: undefined };
        await listingController.createListing(req, res);
        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Missing required fields/i);
    });

    it('should return 400 if sellerProfileId is missing', async () => {
        req.body = { ...validBody(), sellerProfileId: undefined };
        await listingController.createListing(req, res);
        expect(res.statusCode).toBe(400);
    });

    it('should return 400 if foodName is missing', async () => {
        req.body = { ...validBody(), foodName: undefined };
        await listingController.createListing(req, res);
        expect(res.statusCode).toBe(400);
    });

    it('should return 400 if totalQuantity is missing', async () => {
        req.body = { ...validBody(), totalQuantity: undefined };
        await listingController.createListing(req, res);
        expect(res.statusCode).toBe(400);
    });

    it('should return 400 if totalQuantity is not a number', async () => {
        req.body = { ...validBody(), totalQuantity: 'not-a-number' };
        await listingController.createListing(req, res);
        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/must be a number/i);
    });

    it('should return 400 if safety validation fails', async () => {
        PerishabilityEngine.validateSafety.mockReturnValue({
            isValid: false,
            details: 'Pickup window too long for cooked food',
            translationKey: 'error.safety',
            safetyThreshold: '4h'
        });

        req.body = validBody();
        await listingController.createListing(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/safety validation failed/i);
    });

    it('should create a listing and return 201 on valid input', async () => {
        const mockListing = { _id: 'listing-id-1', foodName: 'Fresh Apples', status: 'active' };
        Listing.create.mockResolvedValue(mockListing);

        req.body = validBody();
        await listingController.createListing(req, res);

        expect(res.statusCode).toBe(201);
        expect(Listing.create).toHaveBeenCalledTimes(1);
        expect(res._getJSONData().listing.foodName).toBe('Fresh Apples');
    });

    it('should normalize foodType and category to lowercase', async () => {
        const mockListing = { _id: 'id', foodName: 'Apples' };
        Listing.create.mockResolvedValue(mockListing);

        req.body = { ...validBody(), foodType: 'FRESH_PRODUCE', category: 'PRODUCE' };
        await listingController.createListing(req, res);

        const callArg = Listing.create.mock.calls[0][0];
        expect(callArg.foodType).toBe('fresh_produce');
        expect(callArg.category).toBe('produce');
    });

    it('should default to isFree pricing if no pricing is provided', async () => {
        const mockListing = { _id: 'id', foodName: 'Apples' };
        Listing.create.mockResolvedValue(mockListing);

        req.body = { ...validBody(), pricing: undefined };
        await listingController.createListing(req, res);

        const callArg = Listing.create.mock.calls[0][0];
        expect(callArg.pricing.isFree).toBe(true);
    });
});

// ─────────────────────────────────────────────
// getActiveListings
// ─────────────────────────────────────────────
describe('Listing Controller - getActiveListings', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 200 with a list of active listings', async () => {
        const mockListings = [
            { _id: 'l1', foodName: 'Apples', status: 'active' },
            { _id: 'l2', foodName: 'Bread', status: 'active' }
        ];

        Listing.find.mockReturnValue({
            populate: jest.fn().mockReturnThis(),
            sort: jest.fn().mockResolvedValue(mockListings)
        });

        await listingController.getActiveListings(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData()).toHaveLength(2);
    });

    it('should filter by sellerId if provided in query', async () => {
        req.query = { sellerId: 'seller-abc' };

        Listing.find.mockReturnValue({
            populate: jest.fn().mockReturnThis(),
            sort: jest.fn().mockResolvedValue([])
        });

        await listingController.getActiveListings(req, res);

        const queryArg = Listing.find.mock.calls[0][0];
        expect(queryArg.sellerId).toBe('seller-abc');
    });
});

// ─────────────────────────────────────────────
// updateListing
// ─────────────────────────────────────────────
describe('Listing Controller - updateListing', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 404 if listing is not found', async () => {
        Listing.findByIdAndUpdate.mockResolvedValue(null);
        req.params = { id: 'nonexistent-id' };
        req.body = { foodName: 'Updated Name' };

        await listingController.updateListing(req, res);

        expect(res.statusCode).toBe(404);
        expect(res._getJSONData().error).toMatch(/not found/i);
    });

    it('should return 200 with updated listing on success', async () => {
        const updatedListing = { _id: 'l1', foodName: 'Red Apples' };
        Listing.findByIdAndUpdate.mockResolvedValue(updatedListing);

        req.params = { id: 'l1' };
        req.body = { foodName: 'Red Apples' };

        await listingController.updateListing(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().listing.foodName).toBe('Red Apples');
    });
});

// ─────────────────────────────────────────────
// relistListing
// ─────────────────────────────────────────────
describe('Listing Controller - relistListing', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if pickupWindow is missing', async () => {
        req.params = { id: 'l1' };
        req.body = {};

        await listingController.relistListing(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/pickupWindow/i);
    });

    it('should return 404 if listing is not found', async () => {
        Listing.findById.mockResolvedValue(null);
        req.params = { id: 'nonexistent' };
        req.body = { pickupWindow: { from: new Date().toISOString(), to: future() } };

        await listingController.relistListing(req, res);

        expect(res.statusCode).toBe(404);
    });

    it('should relist a listing and restore quantity', async () => {
        const original = { _id: 'l1', totalQuantity: 10 };
        const relisted = { _id: 'l1', status: 'active', remainingQuantity: 10 };

        Listing.findById.mockResolvedValue(original);
        Listing.findByIdAndUpdate.mockResolvedValue(relisted);

        req.params = { id: 'l1' };
        req.body = { pickupWindow: { from: new Date().toISOString(), to: future() } };

        await listingController.relistListing(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().listing.status).toBe('active');
    });
});

// ─────────────────────────────────────────────
// getSellerStats
// ─────────────────────────────────────────────
describe('Listing Controller - getSellerStats', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if sellerId is not provided', async () => {
        req.query = {};
        await listingController.getSellerStats(req, res);
        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/sellerId is required/i);
    });
});
