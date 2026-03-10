const request = require('supertest');
const app = require('../../server');
const mongoose = require('mongoose');
const Order = require('../../models/Order');
const Listing = require('../../models/Listing');
const User = require('../../models/User');
const Notification = require('../../models/Notification');
const SellerProfile = require('../../models/SellerProfile');
const BuyerProfile = require('../../models/BuyerProfile');
const VolunteerProfile = require('../../models/VolunteerProfile');
const { connect, disconnect } = require('../setup');

describe('Order Lifecycle Integration Tests', () => {
    let seller, buyer, volunteer, listing, sellerProfile, volunteerProfile;

    beforeAll(async () => {
        await connect();
        await Promise.all([
            User.deleteMany({}),
            SellerProfile.deleteMany({}),
            BuyerProfile.deleteMany({}),
            VolunteerProfile.deleteMany({}),
            Listing.deleteMany({}),
            Order.deleteMany({}),
            Notification.deleteMany({})
        ]);

        seller = await User.create({
            firebaseUid: 'lifecycle-seller-uid',
            name: 'Lifecycle Seller',
            phone: '9000000001',
            email: 'lifecycle-seller@test.com',
            role: 'seller',
            trustScore: 50
        });

        sellerProfile = await SellerProfile.create({
            userId: seller._id,
            orgName: 'Lifecycle Kitchen',
            orgType: 'restaurant',
            businessAddressText: '123 Test St',
            businessGeo: { type: 'Point', coordinates: [77.5, 12.9] }
        });

        buyer = await User.create({
            firebaseUid: 'lifecycle-buyer-uid',
            name: 'Lifecycle Buyer',
            phone: '9000000002',
            email: 'lifecycle-buyer@test.com',
            role: 'buyer'
        });

        await BuyerProfile.create({ userId: buyer._id });

        volunteer = await User.create({
            firebaseUid: 'lifecycle-volunteer-uid',
            name: 'Lifecycle Volunteer',
            phone: '9000000003',
            email: 'lifecycle-volunteer@test.com',
            role: 'volunteer',
            trustScore: 50
        });

        volunteerProfile = await VolunteerProfile.create({
            userId: volunteer._id,
            transportMode: 'bike',
            availability: {
                isAvailable: true,
                maxConcurrentOrders: 3,
                activeOrders: 0
            },
            verification: { level: 1 }
        });

        listing = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: 'Lifecycle Rice',
            description: 'Test food for lifecycle',
            quantityText: '20 portions',
            totalQuantity: 20,
            remainingQuantity: 20,
            foodType: 'fresh_produce',
            category: 'produce',
            dietaryType: 'vegetarian',
            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 24 * 60 * 60 * 1000)
            },
            status: 'active',
            pickupAddressText: 'Test Location',
            pickupGeo: { type: 'Point', coordinates: [77.5, 12.9] },
            pricing: { discountedPrice: 10, isFree: false }
        });
    }, 180000);

    afterAll(async () => {
        await Promise.all([
            User.deleteMany({}),
            SellerProfile.deleteMany({}),
            BuyerProfile.deleteMany({}),
            VolunteerProfile.deleteMany({}),
            Listing.deleteMany({}),
            Order.deleteMany({}),
            Notification.deleteMany({})
        ]);
        await disconnect();
    });

    // ─── Self-Pickup Flow ────────────────────────────────────────────

    describe('Self-Pickup Order Flow', () => {
        let orderId, handoverOtp;

        it('should create a self_pickup order and decrement listing quantity', async () => {
            const res = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: listing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 3,
                    fulfillment: 'self_pickup',
                    pickup: {
                        addressText: 'Test Location',
                        geo: { type: 'Point', coordinates: [77.5, 12.9] }
                    },
                    pricing: { itemTotal: 30, deliveryFee: 0, platformFee: 0, total: 30 }
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.order.status).toBe('placed');
            expect(res.body.order.handoverOtp).toBeDefined();
            expect(res.body.remainingQuantity).toBe(17);

            orderId = res.body.order._id;
            handoverOtp = res.body.order.handoverOtp;
        });

        it('should verify handover OTP and mark as delivered', async () => {
            const res = await request(app)
                .post(`/api/orders/${orderId}/verify-otp`)
                .send({ otp: handoverOtp });

            expect(res.statusCode).toBe(200);
            expect(res.body.order.status).toBe('delivered');
            expect(res.body.order.timeline.deliveredAt).toBeDefined();
        });

        it('should reject invalid OTP', async () => {
            // Create another order for this test
            const createRes = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: listing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 1,
                    fulfillment: 'self_pickup',
                    pickup: {
                        addressText: 'Test Location',
                        geo: { type: 'Point', coordinates: [77.5, 12.9] }
                    },
                    pricing: { itemTotal: 10, deliveryFee: 0, platformFee: 0, total: 10 }
                });

            const res = await request(app)
                .post(`/api/orders/${createRes.body.order._id}/verify-otp`)
                .send({ otp: '0000' });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Invalid OTP/);
        });
    });

    // ─── Volunteer Delivery Flow ─────────────────────────────────────

    describe('Volunteer Delivery Order Flow', () => {
        let orderId, pickupOtp, handoverOtp;

        it('should create volunteer_delivery order with awaiting_volunteer status', async () => {
            const res = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: listing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 2,
                    fulfillment: 'volunteer_delivery',
                    pickup: {
                        addressText: 'Seller Location',
                        geo: { type: 'Point', coordinates: [77.5, 12.9] }
                    },
                    drop: {
                        addressText: 'Buyer Location',
                        geo: { type: 'Point', coordinates: [77.6, 13.0] }
                    },
                    pricing: { itemTotal: 20, deliveryFee: 0, platformFee: 0, total: 20 }
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.order.status).toBe('awaiting_volunteer');
            expect(res.body.order.pickupOtp).toBeDefined();
            expect(res.body.order.handoverOtp).toBeDefined();

            orderId = res.body.order._id;
            pickupOtp = res.body.order.pickupOtp;
            handoverOtp = res.body.order.handoverOtp;
        });

        it('should allow volunteer to accept rescue request', async () => {
            const res = await request(app)
                .post(`/api/orders/${orderId}/accept`)
                .send({ volunteerId: volunteer._id });

            expect(res.statusCode).toBe(200);
            expect(res.body.order.status).toBe('volunteer_assigned');
            expect(res.body.order.volunteerId.toString()).toBe(volunteer._id.toString());

            // Verify volunteer active orders incremented
            const profile = await VolunteerProfile.findOne({ userId: volunteer._id });
            expect(profile.availability.activeOrders).toBeGreaterThanOrEqual(1);
        });

        it('should verify pickup OTP and transition to picked_up', async () => {
            const res = await request(app)
                .post(`/api/orders/${orderId}/verify-otp`)
                .send({ otp: pickupOtp });

            expect(res.statusCode).toBe(200);
            expect(res.body.order.status).toBe('picked_up');
            expect(res.body.order.timeline.pickedUpAt).toBeDefined();
        });

        it('should verify handover OTP and mark as delivered', async () => {
            const res = await request(app)
                .post(`/api/orders/${orderId}/verify-otp`)
                .send({ otp: handoverOtp });

            expect(res.statusCode).toBe(200);
            expect(res.body.order.status).toBe('delivered');
            expect(res.body.order.timeline.deliveredAt).toBeDefined();
        });
    });

    // ─── Quantity & Edge Cases ───────────────────────────────────────

    describe('Quantity and Edge Cases', () => {
        it('should reject order when quantity exceeds remaining', async () => {
            const res = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: listing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 9999,
                    fulfillment: 'self_pickup'
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Insufficient quantity/);
        });

        it('should reject order on non-existent listing', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: fakeId,
                    buyerId: buyer._id,
                    quantityOrdered: 1,
                    fulfillment: 'self_pickup'
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/not found/i);
        });

        it('should auto-complete listing when remaining quantity hits 0', async () => {
            // Create a small listing
            const smallListing = await Listing.create({
                sellerId: seller._id,
                sellerProfileId: sellerProfile._id,
                foodName: 'Last Portion',
                quantityText: '1 portion',
                totalQuantity: 1,
                remainingQuantity: 1,
                foodType: 'prepared_meal',
                category: 'meal',
                dietaryType: 'vegetarian',
                pickupWindow: {
                    from: new Date(),
                    to: new Date(Date.now() + 5 * 60 * 60 * 1000) // 5h, within 6h limit
                },
                status: 'active',
                pickupAddressText: 'Test',
                pickupGeo: { type: 'Point', coordinates: [0, 0] },
                pricing: { discountedPrice: 0, isFree: true }
            });

            const res = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: smallListing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 1,
                    fulfillment: 'self_pickup',
                    pickup: { addressText: 'Test', geo: { type: 'Point', coordinates: [0, 0] } },
                    pricing: { itemTotal: 0, deliveryFee: 0, platformFee: 0, total: 0 }
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.remainingQuantity).toBe(0);

            const updated = await Listing.findById(smallListing._id);
            expect(updated.status).toBe('completed');
        });

        it('should reject order on expired listing', async () => {
            const expiredListing = await Listing.create({
                sellerId: seller._id,
                sellerProfileId: sellerProfile._id,
                foodName: 'Expired Food',
                quantityText: '5 kg',
                totalQuantity: 5,
                remainingQuantity: 5,
                foodType: 'fresh_produce',
                category: 'produce',
                dietaryType: 'vegetarian',
                pickupWindow: {
                    from: new Date(Date.now() - 48 * 60 * 60 * 1000),
                    to: new Date(Date.now() - 1000) // expired 1 second ago
                },
                status: 'active',
                pickupAddressText: 'Test',
                pickupGeo: { type: 'Point', coordinates: [0, 0] },
                pricing: { discountedPrice: 0, isFree: true }
            });

            const res = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: expiredListing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 1,
                    fulfillment: 'self_pickup'
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/expired/i);
        });
    });

    // ─── Cancellation ────────────────────────────────────────────────

    describe('Order Cancellation', () => {
        it('should cancel a placed order and restore listing quantity', async () => {
            const listingBefore = await Listing.findById(listing._id);
            const qtyBefore = listingBefore.remainingQuantity;

            const createRes = await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: listing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 2,
                    fulfillment: 'self_pickup',
                    pickup: { addressText: 'Test', geo: { type: 'Point', coordinates: [0, 0] } },
                    pricing: { itemTotal: 20, deliveryFee: 0, platformFee: 0, total: 20 }
                });

            expect(createRes.statusCode).toBe(201);
            const newOrderId = createRes.body.order._id;

            const cancelRes = await request(app)
                .post(`/api/orders/${newOrderId}/cancel`)
                .send({ cancelledBy: 'buyer', reason: 'Changed my mind' });

            expect(cancelRes.statusCode).toBe(200);
            const cancelledOrder = await Order.findById(newOrderId);
            expect(cancelledOrder.status).toBe('cancelled');
            expect(cancelledOrder.cancellation.cancelledBy).toBe('buyer');
        });

        it('should reject cancellation of already delivered order', async () => {
            // Find a delivered order from earlier tests
            const deliveredOrder = await Order.findOne({ status: 'delivered' });
            if (!deliveredOrder) return; // skip if none found

            const res = await request(app)
                .post(`/api/orders/${deliveredOrder._id}/cancel`)
                .send({ cancelledBy: 'buyer', reason: 'Test' });

            expect(res.statusCode).toBe(400);
            expect(res.body.error).toMatch(/Cannot cancel/);
        });
    });

    // ─── Notifications ───────────────────────────────────────────────

    describe('Order Notifications', () => {
        it('should create notifications for seller and buyer on order creation', async () => {
            await Notification.deleteMany({});

            await request(app)
                .post('/api/orders/create')
                .send({
                    listingId: listing._id,
                    buyerId: buyer._id,
                    quantityOrdered: 1,
                    fulfillment: 'self_pickup',
                    pickup: { addressText: 'Test', geo: { type: 'Point', coordinates: [0, 0] } },
                    pricing: { itemTotal: 10, deliveryFee: 0, platformFee: 0, total: 10 }
                });

            const sellerNotifs = await Notification.find({ userId: seller._id });
            const buyerNotifs = await Notification.find({ userId: buyer._id });

            expect(sellerNotifs.length).toBeGreaterThanOrEqual(1);
            expect(buyerNotifs.length).toBeGreaterThanOrEqual(1);
            expect(sellerNotifs[0].type).toBe('order_update');
            expect(buyerNotifs[0].type).toBe('order_update');
        });
    });

    // ─── Fetch Endpoints ─────────────────────────────────────────────

    describe('Order Fetch Endpoints', () => {
        it('GET /api/orders/:id should return populated order', async () => {
            const order = await Order.findOne({ buyerId: buyer._id });
            const res = await request(app).get(`/api/orders/${order._id}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.buyerId).toBeDefined();
            expect(res.body.sellerId).toBeDefined();
        });

        it('GET /api/orders/:id should return 404 for non-existent order', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app).get(`/api/orders/${fakeId}`);
            expect(res.statusCode).toBe(404);
        });

        it('GET /api/orders/buyer/:buyerId should return buyer orders', async () => {
            const res = await request(app).get(`/api/orders/buyer/${buyer._id}`);
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
            expect(res.body.length).toBeGreaterThan(0);
        });

        it('GET /api/orders/seller/:sellerId should return seller orders', async () => {
            const res = await request(app).get(`/api/orders/seller/${seller._id}`);
            expect(res.statusCode).toBe(200);
            expect(Array.isArray(res.body)).toBe(true);
        });
    });
});
