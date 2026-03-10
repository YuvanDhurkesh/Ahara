const reviewController = require('../../controllers/reviewController');
const { Review, ReviewResponse } = require('../../models/Review');
const Order = require('../../models/Order');
const User = require('../../models/User');
const SellerProfile = require('../../models/SellerProfile');
const VolunteerProfile = require('../../models/VolunteerProfile');
const httpMocks = require('node-mocks-http');

jest.mock('../../models/Review');
jest.mock('../../models/Order');
jest.mock('../../models/User');
jest.mock('../../models/SellerProfile');
jest.mock('../../models/VolunteerProfile');

// ─────────────────────────────────────────────
// checkReviewable
// ─────────────────────────────────────────────
describe('Review Controller - checkReviewable', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 404 if order is not found', async () => {
        req.params = { orderId: 'nonexistent' };
        req.query = { buyerId: 'buyer-1' };
        Order.findById.mockReturnValue({ populate: jest.fn().mockReturnValue(null) });

        await reviewController.checkReviewable(req, res);

        expect(res.statusCode).toBe(404);
        expect(res._getJSONData().canReview).toBe(false);
    });

    it('should return 403 if buyer does not own the order', async () => {
        const mockOrder = {
            buyerId: { _id: { toString: () => 'buyer-1' } },
            sellerId: { _id: 'seller-1', name: 'Seller' },
            status: 'delivered',
            fulfillment: 'self_pickup',
        };
        req.params = { orderId: 'order-1' };
        req.query = { buyerId: 'buyer-999' };
        Order.findById.mockReturnValue({ populate: jest.fn().mockReturnValue(mockOrder) });

        await reviewController.checkReviewable(req, res);

        expect(res.statusCode).toBe(403);
        expect(res._getJSONData().canReview).toBe(false);
    });

    it('should return 400 if order is not delivered', async () => {
        const mockOrder = {
            buyerId: { _id: { toString: () => 'buyer-1' } },
            sellerId: { _id: 'seller-1', name: 'Seller' },
            status: 'placed',
            fulfillment: 'self_pickup',
        };
        req.params = { orderId: 'order-1' };
        req.query = { buyerId: 'buyer-1' };
        Order.findById.mockReturnValue({ populate: jest.fn().mockReturnValue(mockOrder) });

        await reviewController.checkReviewable(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().message).toMatch(/must be 'delivered'/);
    });

    it('should return 200 with canReview true for a valid delivered order', async () => {
        const mockOrder = {
            buyerId: { _id: { toString: () => 'buyer-1' } },
            sellerId: { _id: 'seller-1', name: 'Seller' },
            status: 'delivered',
            fulfillment: 'self_pickup',
        };
        req.params = { orderId: 'order-1' };
        req.query = { buyerId: 'buyer-1' };
        Order.findById.mockReturnValue({ populate: jest.fn().mockReturnValue(mockOrder) });
        Review.findOne.mockResolvedValue(null);

        await reviewController.checkReviewable(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().canReview).toBe(true);
    });
});

// ─────────────────────────────────────────────
// createReview
// ─────────────────────────────────────────────
describe('Review Controller - createReview', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if rating is missing', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
        };

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Rating must be between 1 and 5/);
    });

    it('should return 400 if rating is below 1', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 0,
        };

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Rating must be between 1 and 5/);
    });

    it('should return 400 if rating is above 5', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 6,
        };

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
    });

    it('should return 400 if comment is too short', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
            comment: 'Hi',
        };

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/5-500 characters/);
    });

    it('should return 400 if more than 3 tags are provided', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
            tags: ['Quality of food', 'Packaging quality', 'Freshness', 'Value for money'],
        };

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Maximum 3 tags/);
    });

    it('should return 400 if invalid tags are provided', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
            tags: ['InvalidTag'],
        };

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/Invalid tags/);
    });

    it('should return 404 if order is not found', async () => {
        req.body = {
            orderId: 'nonexistent',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
        };
        Order.findById.mockResolvedValue(null);

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(404);
    });

    it('should return 400 if order is not delivered', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
        };
        Order.findById.mockResolvedValue({ status: 'placed', buyerId: { toString: () => 'buyer-1' } });

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/delivered/);
    });

    it('should return 403 if reviewer does not own the order', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-999',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
        };
        Order.findById.mockResolvedValue({ status: 'delivered', buyerId: { toString: () => 'buyer-1' } });

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(403);
    });

    it('should return 400 if duplicate review exists', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 4,
        };
        Order.findById.mockResolvedValue({ status: 'delivered', buyerId: { toString: () => 'buyer-1' } });
        Review.findOne.mockResolvedValue({ _id: 'existing-review' });

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().error).toMatch(/already reviewed/);
    });

    it('should create review and return 201 on valid input', async () => {
        req.body = {
            orderId: 'order-1',
            reviewerId: 'buyer-1',
            targetType: 'seller',
            targetUserId: 'seller-1',
            rating: 5,
            comment: 'Great food quality!',
            tags: ['Quality of food'],
        };
        Order.findById.mockResolvedValue({ status: 'delivered', buyerId: { toString: () => 'buyer-1' } });
        Review.findOne.mockResolvedValue(null);
        User.findById.mockResolvedValue({ name: 'Buyer Name' });
        SellerProfile.findOne.mockResolvedValue({
            stats: { avgRating: 4, ratingCount: 5 },
            save: jest.fn().mockResolvedValue(true),
        });

        const mockSave = jest.fn().mockResolvedValue(true);
        Review.mockImplementation((data) => ({
            ...data,
            save: mockSave,
        }));

        await reviewController.createReview(req, res);

        expect(res.statusCode).toBe(201);
        expect(res._getJSONData().success).toBe(true);
    });
});

// ─────────────────────────────────────────────
// getReviewsByTarget
// ─────────────────────────────────────────────
describe('Review Controller - getReviewsByTarget', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return reviews with analytics for a target user', async () => {
        req.params = { targetUserId: 'seller-1' };
        req.query = { page: '1', limit: '10' };

        const mockReviews = [
            { _id: 'r1', rating: 5, tags: ['Quality of food'], isVerified: true, isAnonymous: false, reviewerName: 'Buyer', createdAt: new Date(), comment: 'Good', responseId: null },
            { _id: 'r2', rating: 4, tags: ['Freshness'], isVerified: true, isAnonymous: true, reviewerName: null, createdAt: new Date(), comment: 'Nice', responseId: null },
        ];

        Review.countDocuments.mockResolvedValue(2);
        Review.find.mockImplementation(() => ({
            populate: jest.fn().mockReturnValue({
                populate: jest.fn().mockReturnValue({
                    sort: jest.fn().mockReturnValue({
                        skip: jest.fn().mockReturnValue({
                            limit: jest.fn().mockResolvedValue(mockReviews),
                        }),
                    }),
                }),
            }),
        }));
        // For analytics query (all reviews)
        Review.find.mockImplementationOnce(() => ({
            populate: jest.fn().mockReturnValue({
                populate: jest.fn().mockReturnValue({
                    sort: jest.fn().mockReturnValue({
                        skip: jest.fn().mockReturnValue({
                            limit: jest.fn().mockResolvedValue(mockReviews),
                        }),
                    }),
                }),
            }),
        })).mockImplementationOnce(() => Promise.resolve(mockReviews));

        await reviewController.getReviewsByTarget(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().success).toBe(true);
    });

    it('should handle empty reviews gracefully', async () => {
        req.params = { targetUserId: 'seller-new' };
        req.query = {};

        Review.countDocuments.mockResolvedValue(0);
        Review.find.mockImplementation(() => ({
            populate: jest.fn().mockReturnValue({
                populate: jest.fn().mockReturnValue({
                    sort: jest.fn().mockReturnValue({
                        skip: jest.fn().mockReturnValue({
                            limit: jest.fn().mockResolvedValue([]),
                        }),
                    }),
                }),
            }),
        }));
        // Second call for analytics
        Review.find.mockImplementationOnce(() => ({
            populate: jest.fn().mockReturnValue({
                populate: jest.fn().mockReturnValue({
                    sort: jest.fn().mockReturnValue({
                        skip: jest.fn().mockReturnValue({
                            limit: jest.fn().mockResolvedValue([]),
                        }),
                    }),
                }),
            }),
        })).mockImplementationOnce(() => Promise.resolve([]));

        await reviewController.getReviewsByTarget(req, res);

        expect(res.statusCode).toBe(200);
    });
});
