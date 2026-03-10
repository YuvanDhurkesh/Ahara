const request = require('supertest');
const app = require('../../server');
const mongoose = require('mongoose');
const { Review } = require('../../models/Review');
const Order = require('../../models/Order');
const User = require('../../models/User');
const Listing = require('../../models/Listing');
const SellerProfile = require('../../models/SellerProfile');
const VolunteerProfile = require('../../models/VolunteerProfile');
const BuyerProfile = require('../../models/BuyerProfile');
const Notification = require('../../models/Notification');
const { connect, disconnect } = require('../setup');

describe('Review Edge Cases Integration Tests', () => {
    let seller, buyer, volunteer, sellerProfile, volunteerProfile;
    let deliveredOrder, pendingOrder;

    beforeAll(async () => {
        await connect();
        await Promise.all([
            User.deleteMany({}),
            SellerProfile.deleteMany({}),
            BuyerProfile.deleteMany({}),
            VolunteerProfile.deleteMany({}),
            Listing.deleteMany({}),
            Order.deleteMany({}),
            Review.deleteMany({}),
            Notification.deleteMany({})
        ]);

        seller = await User.create({
            firebaseUid: 'review-seller-uid',
            name: 'Review Seller',
            phone: '6000000001',
            email: 'review-seller@test.com',
            role: 'seller'
        });

        sellerProfile = await SellerProfile.create({
            userId: seller._id,
            orgName: 'Review Kitchen',
            orgType: 'restaurant',
            businessAddressText: '123 Review St',
            businessGeo: { type: 'Point', coordinates: [77.5, 12.9] },
            stats: { avgRating: 0, ratingCount: 0, totalListings: 0, totalOrdersCompleted: 0 }
        });

        buyer = await User.create({
            firebaseUid: 'review-buyer-uid',
            name: 'Review Buyer',
            phone: '6000000002',
            email: 'review-buyer@test.com',
            role: 'buyer'
        });

        await BuyerProfile.create({ userId: buyer._id });

        volunteer = await User.create({
            firebaseUid: 'review-volunteer-uid',
            name: 'Review Volunteer',
            phone: '6000000003',
            email: 'review-volunteer@test.com',
            role: 'volunteer'
        });

        volunteerProfile = await VolunteerProfile.create({
            userId: volunteer._id,
            transportMode: 'bike',
            availability: { isAvailable: true, maxConcurrentOrders: 3, activeOrders: 0 },
            stats: { avgRating: 0, ratingCount: 0, totalDeliveriesCompleted: 0 }
        });

        const listing = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: 'Reviewable Food',
            quantityText: '50 portions',
            totalQuantity: 50, remainingQuantity: 50,
            foodType: 'fresh_produce', category: 'produce', dietaryType: 'vegetarian',
            pickupWindow: { from: new Date(), to: new Date(Date.now() + 24 * 60 * 60 * 1000) },
            status: 'active', pickupAddressText: 'Test',
            pickupGeo: { type: 'Point', coordinates: [0, 0] },
            pricing: { discountedPrice: 0, isFree: true }
        });

        // Create a delivered order (reviewable)
        deliveredOrder = await Order.create({
            listingId: listing._id,
            sellerId: seller._id,
            buyerId: buyer._id,
            volunteerId: volunteer._id,
            quantityOrdered: 5,
            fulfillment: 'volunteer_delivery',
            status: 'delivered',
            pickup: { addressText: 'Test', geo: { type: 'Point', coordinates: [0, 0] } },
            drop: { addressText: 'Buyer', geo: { type: 'Point', coordinates: [0, 0] } },
            pricing: { itemTotal: 0, total: 0 },
            timeline: { placedAt: new Date(), deliveredAt: new Date() }
        });

        // Create a pending order (not reviewable)
        pendingOrder = await Order.create({
            listingId: listing._id,
            sellerId: seller._id,
            buyerId: buyer._id,
            quantityOrdered: 2,
            fulfillment: 'self_pickup',
            status: 'placed',
            pickup: { addressText: 'Test', geo: { type: 'Point', coordinates: [0, 0] } },
            pricing: { itemTotal: 0, total: 0 },
            timeline: { placedAt: new Date() }
        });
    }, 180000);

    afterAll(async () => {
        await Promise.all([
            User.deleteMany({}), SellerProfile.deleteMany({}), BuyerProfile.deleteMany({}),
            VolunteerProfile.deleteMany({}), Listing.deleteMany({}), Order.deleteMany({}),
            Review.deleteMany({}), Notification.deleteMany({})
        ]);
        await disconnect();
    });

    // ─── Create Review ───────────────────────────────────────────────

    describe('Create Review', () => {
        it('should create a seller review on delivered order', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: deliveredOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 4,
                    comment: 'Great food quality!',
                    tags: ['Quality of food', 'Freshness']
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.review.rating).toBe(4);
            expect(res.body.review.isVerified).toBe(true);

            // Verify seller profile avgRating updated
            const updatedProfile = await SellerProfile.findOne({ userId: seller._id });
            expect(updatedProfile.stats.avgRating).toBe(4);
            expect(updatedProfile.stats.ratingCount).toBe(1);
        });

        it('should prevent duplicate review for same order+reviewer+targetType', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: deliveredOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 5,
                    comment: 'Trying duplicate'
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/already reviewed/i);
        });

        it('should allow volunteer review on same order (different targetType)', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: deliveredOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'volunteer',
                    targetUserId: volunteer._id,
                    rating: 5,
                    comment: 'Super fast delivery!',
                    tags: ['Delivery speed']
                });

            expect(res.statusCode).toBe(201);

            // Verify volunteer profile avgRating updated
            const updatedProfile = await VolunteerProfile.findOne({ userId: volunteer._id });
            expect(updatedProfile.stats.avgRating).toBe(5);
            expect(updatedProfile.stats.ratingCount).toBe(1);
        });

        it('should reject review on non-delivered order', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: pendingOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 3,
                    comment: 'Should not work'
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/delivered/i);
        });

        it('should reject rating outside 1-5 range', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: deliveredOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 6
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Rating must be between 1 and 5/i);
        });

        it('should reject more than 3 tags', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: deliveredOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 4,
                    tags: ['Quality of food', 'Freshness', 'Packaging quality', 'Value for money']
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Maximum 3 tags/i);
        });

        it('should reject invalid tag values', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: deliveredOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 4,
                    tags: ['Nonexistent tag']
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Invalid tags/i);
        });

        it('should support anonymous reviews', async () => {
            // Create a new delivered order for this test
            const anonOrder = await Order.create({
                listingId: deliveredOrder.listingId,
                sellerId: seller._id,
                buyerId: buyer._id,
                quantityOrdered: 1,
                fulfillment: 'self_pickup',
                status: 'delivered',
                pickup: { addressText: 'Test', geo: { type: 'Point', coordinates: [0, 0] } },
                pricing: { itemTotal: 0, total: 0 },
                timeline: { placedAt: new Date(), deliveredAt: new Date() }
            });

            const res = await request(app)
                .post('/api/reviews')
                .send({
                    orderId: anonOrder._id,
                    reviewerId: buyer._id,
                    targetType: 'seller',
                    targetUserId: seller._id,
                    rating: 3,
                    comment: 'Anonymous feedback',
                    isAnonymous: true
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.review.reviewerName).toBeNull();
            expect(res.body.review.isAnonymous).toBe(true);
        });
    });

    // ─── Check Reviewable ────────────────────────────────────────────

    describe('Check Reviewable', () => {
        it('should confirm delivered order is reviewable', async () => {
            const res = await request(app)
                .get(`/api/reviews/check-reviewable/${deliveredOrder._id}?buyerId=${buyer._id}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.canReview).toBe(true);
            expect(res.body.seller).toBeDefined();
            expect(res.body.volunteer).toBeDefined();
        });

        it('should reject reviewability check for non-delivered order', async () => {
            const res = await request(app)
                .get(`/api/reviews/check-reviewable/${pendingOrder._id}?buyerId=${buyer._id}`);

            expect(res.statusCode).toBe(400);
            expect(res.body.canReview).toBe(false);
        });

        it('should return 404 for non-existent order', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .get(`/api/reviews/check-reviewable/${fakeId}?buyerId=${buyer._id}`);

            expect(res.statusCode).toBe(404);
        });
    });

    // ─── Get Reviews by Target ───────────────────────────────────────

    describe('Get Reviews by Target', () => {
        it('should return reviews with analytics for seller', async () => {
            const res = await request(app)
                .get(`/api/reviews/target/${seller._id}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.analytics).toBeDefined();
            expect(res.body.analytics.avgRating).toBeGreaterThan(0);
            expect(res.body.analytics.totalReviews).toBeGreaterThan(0);
            expect(res.body.analytics.ratingDistribution).toBeDefined();
            expect(res.body.reviews.length).toBeGreaterThan(0);
        });

        it('should return empty results for user with no reviews', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .get(`/api/reviews/target/${fakeId}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.analytics.totalReviews).toBe(0);
            expect(res.body.reviews).toEqual([]);
        });
    });
});
