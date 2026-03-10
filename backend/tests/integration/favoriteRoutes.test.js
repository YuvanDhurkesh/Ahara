const request = require('supertest');
const app = require('../../server');
const User = require('../../models/User');
const BuyerProfile = require('../../models/BuyerProfile');
const SellerProfile = require('../../models/SellerProfile');
const Listing = require('../../models/Listing');
const { connect, disconnect } = require('../setup');

describe('Favorite Routes Integration Tests', () => {
    let buyer, seller, sellerProfile, listing1, listing2;

    beforeAll(async () => {
        await connect();
        await Promise.all([
            User.deleteMany({}),
            BuyerProfile.deleteMany({}),
            SellerProfile.deleteMany({}),
            Listing.deleteMany({})
        ]);

        buyer = await User.create({
            firebaseUid: 'fav-buyer-uid',
            name: 'Fav Buyer',
            phone: '7000000001',
            email: 'fav-buyer@test.com',
            role: 'buyer'
        });

        await BuyerProfile.create({ userId: buyer._id });

        seller = await User.create({
            firebaseUid: 'fav-seller-uid',
            name: 'Fav Seller',
            phone: '7000000002',
            email: 'fav-seller@test.com',
            role: 'seller'
        });

        sellerProfile = await SellerProfile.create({
            userId: seller._id,
            orgName: 'Fav Kitchen',
            orgType: 'restaurant',
            businessAddressText: '123 Fav St',
            businessGeo: { type: 'Point', coordinates: [77.5, 12.9] }
        });

        listing1 = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: 'Favorite Item 1',
            quantityText: '10 kg',
            totalQuantity: 10,
            remainingQuantity: 10,
            foodType: 'fresh_produce',
            category: 'produce',
            dietaryType: 'vegetarian',
            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 24 * 60 * 60 * 1000)
            },
            status: 'active',
            pickupAddressText: 'Test',
            pickupGeo: { type: 'Point', coordinates: [77.5, 12.9] },
            pricing: { discountedPrice: 0, isFree: true }
        });

        listing2 = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: 'Favorite Item 2',
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
            pickupGeo: { type: 'Point', coordinates: [77.5, 12.9] },
            pricing: { discountedPrice: 0, isFree: true }
        });
    }, 60000);

    afterAll(async () => {
        await Promise.all([
            User.deleteMany({}),
            BuyerProfile.deleteMany({}),
            SellerProfile.deleteMany({}),
            Listing.deleteMany({})
        ]);
        await disconnect();
    }, 60000);

    // ─── Toggle Favorite Listing ─────────────────────────────────────

    describe('Toggle Favorite Listing', () => {
        it('should add listing to favorites', async () => {
            const res = await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-listing`)
                .send({ listingId: listing1._id.toString() });

            expect(res.statusCode).toBe(200);
            expect(res.body.isFavorited).toBe(true);
            expect(res.body.favouriteListings).toContain(listing1._id.toString());
        });

        it('should remove listing from favorites on second toggle', async () => {
            const res = await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-listing`)
                .send({ listingId: listing1._id.toString() });

            expect(res.statusCode).toBe(200);
            expect(res.body.isFavorited).toBe(false);
            expect(res.body.favouriteListings).not.toContain(listing1._id.toString());
        });

        it('should handle multiple favorites', async () => {
            // Add both
            await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-listing`)
                .send({ listingId: listing1._id.toString() });
            await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-listing`)
                .send({ listingId: listing2._id.toString() });

            const profile = await BuyerProfile.findOne({ userId: buyer._id });
            expect(profile.favouriteListings.length).toBe(2);
        });

        it('should reject without listingId', async () => {
            const res = await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-listing`)
                .send({});

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/listingId is required/i);
        });

        it('should return 404 for non-existent user', async () => {
            const res = await request(app)
                .post('/api/users/nonexistent-uid/toggle-favorite-listing')
                .send({ listingId: listing1._id.toString() });

            expect(res.statusCode).toBe(404);
        });
    });

    // ─── Get Favorite Listings ───────────────────────────────────────

    describe('Get Favorite Listings', () => {
        it('should return favorited listings with full data', async () => {
            const res = await request(app)
                .get(`/api/listings/favorites/${buyer.firebaseUid}`);

            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
            expect(res.body.length).toBeGreaterThanOrEqual(1);
            // Should have listing data, not just IDs
            expect(res.body[0].foodName).toBeDefined();
        });

        it('should return empty array for user with no favorites', async () => {
            const newUser = await User.create({
                firebaseUid: 'no-fav-uid',
                name: 'No Fav',
                phone: '7000000099',
                email: 'nofav@test.com',
                role: 'buyer'
            });
            await BuyerProfile.create({ userId: newUser._id });

            const res = await request(app)
                .get(`/api/listings/favorites/${newUser.firebaseUid}`);

            expect(res.statusCode).toBe(200);
            expect(res.body).toEqual([]);
        });
    });

    // ─── Toggle Favorite Seller ──────────────────────────────────────

    describe('Toggle Favorite Seller', () => {
        it('should add seller to favorites', async () => {
            const res = await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-seller`)
                .send({ sellerId: seller._id.toString() });

            expect(res.statusCode).toBe(200);
            expect(res.body.isFavorited).toBe(true);
        });

        it('should remove seller from favorites on second toggle', async () => {
            const res = await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-seller`)
                .send({ sellerId: seller._id.toString() });

            expect(res.statusCode).toBe(200);
            expect(res.body.isFavorited).toBe(false);
        });

        it('should reject without sellerId', async () => {
            const res = await request(app)
                .post(`/api/users/${buyer.firebaseUid}/toggle-favorite-seller`)
                .send({});

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/sellerId is required/i);
        });
    });
});
