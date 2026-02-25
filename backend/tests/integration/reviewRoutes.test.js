const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const Order = require('../../models/Order');
const Listing = require('../../models/Listing');
const SellerProfile = require('../../models/SellerProfile');
const Review = require('../../models/Review');
const { connect, disconnect } = require('../setup');
const mongoose = require('mongoose');

describe('Review Routes Integration Tests', () => {
    let reviewer;
    let seller;
    let sellerProfile;
    let order;
    let listing;

    beforeAll(async () => {
        await connect();
    }, 60000);

    afterAll(async () => {
        await disconnect();
    }, 60000);

    beforeEach(async () => {
        await User.deleteMany({});
        await Order.deleteMany({});
        await Listing.deleteMany({});
        await SellerProfile.deleteMany({});
        await Review.deleteMany({});

        // Create reviewer (buyer)
        reviewer = await User.create({
            firebaseUid: 'reviewer-uid',
            name: 'Reviewer',
            email: 'reviewer@test.com',
            role: 'buyer',
            phone: '1111111111'
        });

        // Create seller
        seller = await User.create({
            firebaseUid: 'seller-uid',
            name: 'Seller',
            email: 'seller@test.com',
            role: 'seller',
            phone: '2222222222'
        });

        // Create seller profile
        sellerProfile = await SellerProfile.create({
            userId: seller._id,
            orgName: 'Test Org',
            orgType: 'restaurant',
            stats: { avgRating: 0, ratingCount: 0 }
        });

        // Create listing
        listing = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: 'Test Food',
            quantityText: '1kg',
            totalQuantity: 1,
            foodType: 'fresh_produce',
            category: 'produce',
            pickupWindow: { from: new Date(), to: new Date(Date.now() + 3600000) },
            pricing: { originalPrice: 100, discountedPrice: 0, isFree: true }
        });

        // Create order
        order = await Order.create({
            listingId: listing._id,
            sellerId: seller._id,
            buyerId: reviewer._id,
            quantityOrdered: 1,
            fulfillment: 'self_pickup',
            status: 'delivered'
        });
    });

    it('POST /api/reviews should create a review and update seller profile', async () => {
        const res = await request(app)
            .post('/api/reviews')
            .send({
                orderId: order._id.toString(),
                reviewerId: reviewer._id.toString(),
                targetType: 'seller',
                targetUserId: seller._id.toString(),
                rating: 5,
                comment: 'Excellent food!'
            });

        expect(res.statusCode).toBe(201);
        expect(res.body.review.rating).toBe(5);

        // Verify profile update
        const updatedProfile = await SellerProfile.findOne({ userId: seller._id });
        expect(updatedProfile.stats.ratingCount).toBe(1);
        expect(updatedProfile.stats.avgRating).toBe(5);
    });

    it('GET /api/reviews/target/:targetUserId should get reviews for a user', async () => {
        await Review.create({
            orderId: order._id,
            reviewerId: reviewer._id,
            targetType: 'seller',
            targetUserId: seller._id,
            rating: 4,
            comment: 'Good'
        });

        const res = await request(app).get(`/api/reviews/target/${seller._id}`);

        expect(res.statusCode).toBe(200);
        expect(res.body.length).toBe(1);
        expect(res.body[0].rating).toBe(4);
    });
});
