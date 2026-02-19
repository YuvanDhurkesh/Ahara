const request = require('supertest');
const app = require('../../server');
const mongoose = require('mongoose');
const Listing = require('../../models/Listing');
const User = require('../../models/User');
const SellerProfile = require('../../models/SellerProfile');
const { connect, disconnect } = require('../setup');

describe('Listing Routes Integration Tests', () => {
    let sellerUser;
    let sellerProfile;
    let createdListingId;

    // Setup: Create a test user (seller) and profile before tests
    beforeAll(async () => {
        await connect();
        
        // Clear collections
        try {
            await User.deleteMany({});
            await SellerProfile.deleteMany({});
            await Listing.deleteMany({});
        } catch (e) {
            console.error('Cleanup error:', e.message);
        }

        sellerUser = await User.create({
            firebaseUid: 'seller-test-uid-' + Date.now(),
            name: 'Test Seller',
            email: 'seller@test.com',
            role: 'seller',
            phone: '9876543210'
        });

        sellerProfile = await SellerProfile.create({
            userId: sellerUser._id,
            orgName: 'Test Kitchen',
            orgType: 'restaurant',
            businessAddressText: '123 Food St',
            businessGeo: {
                type: 'Point',
                coordinates: [77.5946, 12.9716]
            }
        });
    }, 60000);

    // Cleanup after all tests
    afterAll(async () => {
        try {
            await User.deleteMany({});
            await SellerProfile.deleteMany({});
            await Listing.deleteMany({});
        } catch (e) {
            console.error('Final cleanup error:', e.message);
        }
        await disconnect();
    }, 60000);

    it('POST /api/listings/create should create a new food donation', async () => {
        const res = await request(app)
            .post('/api/listings/create')
            .send({
                sellerId: sellerUser._id.toString(),
                sellerProfileId: sellerProfile._id.toString(),
                foodName: 'Fresh Apples',
                description: 'A box of fresh apples',
                quantityText: '5kg',
                totalQuantity: 5,
                foodType: 'fresh_produce', // Valid type with 48h shelf life
                dietaryType: 'vegetarian',
                category: 'produce',
                pickupWindow: {
                    from: new Date().toISOString(),
                    to: new Date(Date.now() + 86400000).toISOString() // 24 hours from now (safe for produce)
                },
                pickupAddressText: '123 Test St',
                pickupGeo: {
                    type: 'Point',
                    coordinates: [77.5946, 12.9716]
                },
                pricing: {
                    originalPrice: 100,
                    discountedPrice: 0,
                    isFree: true
                }
            });

        expect(res.statusCode).toBe(201);
        expect(res.body.message).toBe('Listing created successfully');
        expect(res.body.listing.foodName).toBe('Fresh Apples');

        createdListingId = res.body.listing._id;
    });

    it('GET /api/listings/active should return created listing', async () => {
        const res = await request(app).get('/api/listings/active');

        expect(res.statusCode).toBe(200);
        expect(Array.isArray(res.body)).toBeTruthy();

        // Find our listing in the results
        const listing = res.body.find(l => l._id.toString() === createdListingId.toString());
        expect(listing).toBeDefined();
        expect(listing.foodName).toBe('Fresh Apples');
    });

    it('PUT /api/listings/update/:id should update listing details', async () => {
        if (!createdListingId) return; // Skip if create failed

        const res = await request(app)
            .put(`/api/listings/update/${createdListingId}`)
            .send({
                foodName: 'Fresh Red Apples',
                totalQuantity: 4
            });

        expect(res.statusCode).toBe(200);
        expect(res.body.listing.foodName).toBe('Fresh Red Apples');
        expect(res.body.listing.totalQuantity).toBe(4);
    });

    it('GET /api/listings/active should reflect updated listing', async () => {
        if (!createdListingId) return; // Skip if create failed

        const res = await request(app).get('/api/listings/active');

        expect(res.statusCode).toBe(200);
        // Verify the updated listing is in the feed
        const listing = res.body.find(l => l._id.toString() === createdListingId.toString());
        expect(listing).toBeDefined();
        expect(listing.foodName).toBe('Fresh Red Apples');
        expect(listing.totalQuantity).toBe(4);
    });
});