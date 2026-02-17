const request = require('supertest');
const app = require('../../server');
const mongoose = require('mongoose');
const Order = require('../../models/Order');
const Listing = require('../../models/Listing');
const User = require('../../models/User');
const SellerProfile = require('../../models/SellerProfile');
const { connect, disconnect } = require('../setup');

describe('Order Routes Integration Tests', () => {
    jest.setTimeout(60000);
    let seller, buyer, listing, sellerProfile;

    beforeAll(async () => {
        await connect();
        await User.deleteMany({});
        await SellerProfile.deleteMany({});
        await Listing.deleteMany({});
        await Order.deleteMany({});

        // Create Users
        seller = await User.create({
            role: 'seller',
            name: 'Test Seller',
            phone: '9876543210',
            firebaseUid: 'seller-test-uid',
            email: 'seller@example.com'
        });

        sellerProfile = await SellerProfile.create({
            userId: seller._id,
            orgName: 'Test Kitchen',
            orgType: 'restaurant',
            businessAddressText: '123 Food St',
            businessGeo: {
                type: 'Point',
                coordinates: [77.5946, 12.9716]
            }
        });

        buyer = await User.create({
            firebaseUid: 'buyer-uid',
            name: 'Buyer',
            phone: '1234567890',
            email: 'buyer@test.com',
            role: 'buyer'
        });

        // Create Listing
        listing = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: 'Test Produce',
            description: 'Fresh test food',
            quantityText: '10kg',
            totalQuantity: 10,
            remainingQuantity: 10,
            foodType: 'fresh_produce', // Valid type with 48h shelf life
            category: 'produce',
            dietaryType: 'vegetarian',

            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 86400000) // 24 hours safe for produce
            },
            status: 'active',
            pickupAddressText: 'Seller Location',
            pickupGeo: {
                type: 'Point',
                coordinates: [0, 0]
            },
            pricing: {
                discountedPrice: 10,
                isFree: false
            }
        });
    }, 60000);

    afterAll(async () => {
        await User.deleteMany({});
        await SellerProfile.deleteMany({});
        await Listing.deleteMany({});
        await Order.deleteMany({});
        await disconnect();
    });

    it('POST /api/orders/create should create a new order', async () => {
        const res = await request(app)
            .post('/api/orders/create')
            .send({
                listingId: listing._id,
                buyerId: buyer._id,
                quantityOrdered: 5,
                fulfillment: 'self_pickup',
                pickup: {
                    addressText: 'Seller Location',
                    geo: { type: 'Point', coordinates: [0, 0] }
                },
                pricing: {
                    itemTotal: 50,
                    deliveryFee: 0,
                    platformFee: 0,
                    total: 50
                }
            });

        if (res.statusCode !== 201) {
            console.log("!!! ORDER CREATION FAILED !!!");
            console.log(JSON.stringify(res.body, null, 2));
        }

        expect(res.statusCode).toBe(201);
        expect(res.body.message).toBe('Order placed successfully');
        expect(res.body.order.status).toBe('placed');
        expect(res.body.remainingQuantity).toBe(5);

        // Verify global DB state
        const updatedListing = await Listing.findById(listing._id);
        expect(updatedListing.remainingQuantity).toBe(5);
    });

    it('POST /api/orders/create should fail if quantity is insufficient', async () => {
        const res = await request(app)
            .post('/api/orders/create')
            .send({
                listingId: listing._id,
                buyerId: buyer._id,
                quantityOrdered: 100, // More than remaining (5)
                fulfillment: 'self_pickup'
            });

        expect(res.statusCode).toBe(400);
        expect(res.body.error).toMatch(/Insufficient quantity/);
    });
});
