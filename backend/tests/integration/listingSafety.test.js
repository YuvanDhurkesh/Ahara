const request = require('supertest');
const app = require('../../server');
const Listing = require('../../models/Listing');
const User = require('../../models/User');
const Order = require('../../models/Order');
const SellerProfile = require('../../models/SellerProfile');
const { connect, disconnect } = require('../setup');

describe('Listing Safety & Lifecycle Integration Tests', () => {
    let seller, sellerProfile;

    beforeAll(async () => {
        await connect();
        await Promise.all([
            User.deleteMany({}),
            SellerProfile.deleteMany({}),
            Listing.deleteMany({}),
            Order.deleteMany({})
        ]);

        seller = await User.create({
            firebaseUid: 'safety-seller-uid-' + Date.now(),
            name: 'Safety Seller',
            email: 'safety-seller@test.com',
            role: 'seller',
            phone: '8000000001'
        });

        sellerProfile = await SellerProfile.create({
            userId: seller._id,
            orgName: 'Safety Kitchen',
            orgType: 'restaurant',
            businessAddressText: '123 Safe St',
            businessGeo: { type: 'Point', coordinates: [77.5, 12.9] }
        });
    }, 60000);

    afterAll(async () => {
        await Promise.all([
            User.deleteMany({}),
            SellerProfile.deleteMany({}),
            Listing.deleteMany({}),
            Order.deleteMany({})
        ]);
        await disconnect();
    }, 60000);

    // ─── Safety Validation ───────────────────────────────────────────

    describe('Perishability Safety on Listing Creation', () => {
        it('should reject prepared_meal with pickup window > 6 hours', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({
                    sellerId: seller._id.toString(),
                    sellerProfileId: sellerProfile._id.toString(),
                    foodName: 'Unsafe Biryani',
                    totalQuantity: 5,
                    foodType: 'prepared_meal',
                    dietaryType: 'non_veg',
                    category: 'meal',
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 12 * 60 * 60 * 1000).toISOString() // 12h > 6h
                    },
                    pickupAddressText: '123 Test St',
                    pickupGeo: { type: 'Point', coordinates: [77.5, 12.9] },
                    pricing: { isFree: true }
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Safety validation failed/i);
            expect(res.body.translationKey).toBe('error_unsafe_donation');
        });

        it('should accept prepared_meal with pickup window within 6 hours', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({
                    sellerId: seller._id.toString(),
                    sellerProfileId: sellerProfile._id.toString(),
                    foodName: 'Safe Biryani',
                    totalQuantity: 10,
                    foodType: 'prepared_meal',
                    dietaryType: 'non_veg',
                    category: 'meal',
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 5 * 60 * 60 * 1000).toISOString() // 5h < 6h
                    },
                    pickupAddressText: '123 Test St',
                    pickupGeo: { type: 'Point', coordinates: [77.5, 12.9] },
                    pricing: { isFree: true }
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.listing.isSafetyValidated).toBe(true);
            expect(res.body.listing.safetyStatus).toBe('validated');
        });

        it('should reject bakery_item with pickup window > 24 hours', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({
                    sellerId: seller._id.toString(),
                    sellerProfileId: sellerProfile._id.toString(),
                    foodName: 'Old Cake',
                    totalQuantity: 3,
                    foodType: 'bakery_item',
                    dietaryType: 'vegetarian',
                    category: 'bakery',
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString() // 48h > 24h
                    },
                    pickupAddressText: '123 Test St',
                    pricing: { isFree: true }
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Safety validation failed/i);
        });

        it('should accept fresh_produce with 24h window (within 48h limit)', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({
                    sellerId: seller._id.toString(),
                    sellerProfileId: sellerProfile._id.toString(),
                    foodName: 'Fresh Mangoes',
                    totalQuantity: 15,
                    foodType: 'fresh_produce',
                    dietaryType: 'vegan',
                    category: 'produce',
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
                    },
                    pickupAddressText: '123 Test St',
                    pickupGeo: { type: 'Point', coordinates: [77.5, 12.9] },
                    pricing: { originalPrice: 200, discountedPrice: 50, isFree: false }
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.listing.foodName).toBe('Fresh Mangoes');
        });

        it('should accept packaged_food with 7-day window (within 30d limit)', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({
                    sellerId: seller._id.toString(),
                    sellerProfileId: sellerProfile._id.toString(),
                    foodName: 'Sealed Biscuits',
                    totalQuantity: 50,
                    foodType: 'packaged_food',
                    dietaryType: 'vegetarian',
                    category: 'packaged',
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
                    },
                    pickupAddressText: '123 Test St',
                    pricing: { discountedPrice: 30, isFree: false }
                });

            expect(res.statusCode).toBe(201);
        });
    });

    // ─── Listing CRUD & Validation ───────────────────────────────────

    describe('Listing Validation', () => {
        it('should reject listing without required fields', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({ foodName: 'Incomplete' });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Missing required fields/i);
        });

        it('should reject non-numeric totalQuantity', async () => {
            const res = await request(app)
                .post('/api/listings/create')
                .send({
                    sellerId: seller._id.toString(),
                    sellerProfileId: sellerProfile._id.toString(),
                    foodName: 'Bad Quantity',
                    totalQuantity: 'lots',
                    foodType: 'prepared_meal',
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString()
                    }
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/totalQuantity must be a number/i);
        });
    });

    // ─── Active / Expired / Completed Queries ────────────────────────

    describe('Listing Query Filters', () => {
        it('GET /api/listings/active should only return active listings with remaining quantity', async () => {
            const res = await request(app).get('/api/listings/active');
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);

            for (const l of res.body) {
                expect(l.status).toBe('active');
                expect(l.remainingQuantity).toBeGreaterThan(0);
            }
        });

        it('GET /api/listings/active should not include expired listings', async () => {
            const expired = await Listing.create({
                sellerId: seller._id,
                sellerProfileId: sellerProfile._id,
                foodName: 'Expired Item',
                quantityText: '5 kg',
                totalQuantity: 5,
                remainingQuantity: 5,
                foodType: 'prepared_meal',
                category: 'meal',
                dietaryType: 'vegetarian',
                pickupWindow: {
                    from: new Date(Date.now() - 10 * 60 * 60 * 1000),
                    to: new Date(Date.now() - 1000)
                },
                status: 'active',
                pickupAddressText: 'Test',
                pricing: { discountedPrice: 0, isFree: true }
            });

            const res = await request(app).get('/api/listings/active');
            const ids = res.body.map(l => l._id.toString());
            expect(ids).not.toContain(expired._id.toString());
        });

        it('GET /api/listings/expired should return expired listings', async () => {
            const res = await request(app)
                .get(`/api/listings/expired?sellerId=${seller._id}`);
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });
    });

    // ─── Relist ──────────────────────────────────────────────────────

    describe('Relist Expired Listing', () => {
        it('should relist with new pickup window and restore quantity', async () => {
            const expired = await Listing.create({
                sellerId: seller._id,
                sellerProfileId: sellerProfile._id,
                foodName: 'Relist Item',
                quantityText: '10 portions',
                totalQuantity: 10,
                remainingQuantity: 3,
                foodType: 'fresh_produce',
                category: 'produce',
                dietaryType: 'vegetarian',
                pickupWindow: {
                    from: new Date(Date.now() - 48 * 60 * 60 * 1000),
                    to: new Date(Date.now() - 1000)
                },
                status: 'expired',
                pickupAddressText: 'Test',
                pricing: { discountedPrice: 0, isFree: true }
            });

            const res = await request(app)
                .put(`/api/listings/relist/${expired._id}`)
                .send({
                    pickupWindow: {
                        from: new Date().toISOString(),
                        to: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
                    }
                });

            expect(res.statusCode).toBe(200);
            expect(res.body.listing.status).toBe('active');
            expect(res.body.listing.remainingQuantity).toBe(10); // restored to totalQuantity
        });

        it('should reject relist without pickup window', async () => {
            const listing = await Listing.findOne({ sellerId: seller._id });
            const res = await request(app)
                .put(`/api/listings/relist/${listing._id}`)
                .send({});

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/pickupWindow/i);
        });
    });

    // ─── Delete ──────────────────────────────────────────────────────

    describe('Delete Listing', () => {
        it('should delete listing with no active orders', async () => {
            const toDelete = await Listing.create({
                sellerId: seller._id,
                sellerProfileId: sellerProfile._id,
                foodName: 'Delete Me',
                quantityText: '5 packs',
                totalQuantity: 5,
                remainingQuantity: 5,
                foodType: 'packaged_food',
                category: 'packaged',
                dietaryType: 'vegetarian',
                pickupWindow: {
                    from: new Date(),
                    to: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
                },
                status: 'active',
                pickupAddressText: 'Test',
                pricing: { discountedPrice: 0, isFree: true }
            });

            const res = await request(app)
                .delete(`/api/listings/delete/${toDelete._id}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.message).toMatch(/deleted successfully/i);

            const check = await Listing.findById(toDelete._id);
            expect(check).toBeNull();
        });

        it('should return 404 for non-existent listing', async () => {
            const mongoose = require('mongoose');
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .delete(`/api/listings/delete/${fakeId}`);

            expect(res.statusCode).toBe(404);
        });
    });
});
