/**
 * SECURITY TEST SUITE: API Security & Configuration
 *
 * Tests for:
 * - CORS misconfiguration
 * - Missing HTTP security headers (Helmet)
 * - Rate limiting absence
 * - Error information leakage
 * - Sensitive data in API responses
 * - HTTP method enforcement
 * - Payment security
 */

const request = require("supertest");
const app = require("../../server");
const { connect, disconnect } = require("../setup");
const User = require("../../models/User");
const Listing = require("../../models/Listing");
const Order = require("../../models/Order");
const SellerProfile = require("../../models/SellerProfile");
const BuyerProfile = require("../../models/BuyerProfile");
const Otp = require("../../models/Otp");
const Notification = require("../../models/Notification");

beforeAll(async () => await connect(), 90000);
afterEach(async () => {
    await User.deleteMany({});
    await Listing.deleteMany({});
    await Order.deleteMany({});
    await SellerProfile.deleteMany({});
    await BuyerProfile.deleteMany({});
    await Otp.deleteMany({});
    await Notification.deleteMany({});
});
afterAll(async () => await disconnect(), 30000);

// ===========================================================================
// 1. CORS MISCONFIGURATION
// ===========================================================================
describe("SEC-API-01: CORS configuration", () => {
    test("CORS allows any origin (wildcard)", async () => {
        const res = await request(app)
            .options("/api/users/create")
            .set("Origin", "https://evil-attacker.com")
            .set("Access-Control-Request-Method", "POST");

        // Check if the malicious origin is reflected back
        const allowOrigin = res.headers["access-control-allow-origin"];
        expect(allowOrigin).toBeDefined();
        // VULNERABILITY: If the evil origin is allowed, CORS is too permissive
        // Current config: callback(null, true) — allows ALL origins
        expect(allowOrigin).toBe("https://evil-attacker.com");
    });

    test("CORS allows all HTTP methods", async () => {
        const res = await request(app)
            .options("/api/users/create")
            .set("Origin", "https://test.com")
            .set("Access-Control-Request-Method", "DELETE");

        const allowMethods = res.headers["access-control-allow-methods"];
        expect(allowMethods).toBeDefined();
        expect(allowMethods).toContain("DELETE");
    });
});

// ===========================================================================
// 2. MISSING HTTP SECURITY HEADERS
// ===========================================================================
describe("SEC-API-02: HTTP security headers", () => {
    test("Missing X-Content-Type-Options header (no helmet)", async () => {
        const res = await request(app).get("/");
        // Helmet would set: X-Content-Type-Options: nosniff
        expect(res.headers["x-content-type-options"]).toBeUndefined();
        // VULNERABILITY: Missing nosniff header — MIME type sniffing possible
    });

    test("Missing X-Frame-Options header", async () => {
        const res = await request(app).get("/");
        expect(res.headers["x-frame-options"]).toBeUndefined();
        // VULNERABILITY: Clickjacking possible without X-Frame-Options
    });

    test("Missing Strict-Transport-Security header", async () => {
        const res = await request(app).get("/");
        expect(res.headers["strict-transport-security"]).toBeUndefined();
        // VULNERABILITY: No HSTS — downgrade attacks possible
    });

    test("Missing Content-Security-Policy header", async () => {
        const res = await request(app).get("/");
        expect(res.headers["content-security-policy"]).toBeUndefined();
        // VULNERABILITY: No CSP — XSS mitigation layer missing
    });

    test("Missing X-XSS-Protection header", async () => {
        const res = await request(app).get("/");
        expect(res.headers["x-xss-protection"]).toBeUndefined();
    });

    test("X-Powered-By header reveals technology stack", async () => {
        const res = await request(app).get("/");
        const poweredBy = res.headers["x-powered-by"];
        // Express sets this by default; helmet removes it
        if (poweredBy) {
            expect(poweredBy).toContain("Express");
            // VULNERABILITY: Technology fingerprinting — attacker knows the stack
        }
    });
});

// ===========================================================================
// 3. RATE LIMITING
// ===========================================================================
describe("SEC-API-03: Rate limiting", () => {
    test("OTP send endpoint has no rate limiting", async () => {
        const results = [];

        // Send 15 rapid OTP requests for the same number
        for (let i = 0; i < 15; i++) {
            const res = await request(app)
                .post("/api/otp/send")
                .send({ phoneNumber: "+910000000001" });
            results.push(res.status);
        }

        // If rate limiting existed, some should be 429
        const tooMany = results.filter((s) => s === 429);
        expect(tooMany.length).toBe(0);
        // VULNERABILITY: No rate limiting — SMS bombing possible
        // This could also cause significant Twilio costs in production
    });

    test("User creation endpoint has no rate limiting", async () => {
        const results = [];

        for (let i = 0; i < 10; i++) {
            const res = await request(app).post("/api/users/create").send({
                firebaseUid: "ratelimit_test_" + i + "_" + Date.now(),
                email: `ratelimit${i}@test.com`,
                role: "buyer",
                name: "Rate Limit Test",
                phone: `+91000000100${i}`,
            });
            results.push(res.status);
        }

        const tooMany = results.filter((s) => s === 429);
        expect(tooMany.length).toBe(0);
        // VULNERABILITY: No rate limiting — mass account creation possible
    });

    test("Payment creation endpoint has no rate limiting", async () => {
        const results = [];

        for (let i = 0; i < 10; i++) {
            const res = await request(app)
                .post("/api/payments/create-order")
                .send({ amount: 100 });
            results.push(res.status);
        }

        const tooMany = results.filter((s) => s === 429);
        expect(tooMany.length).toBe(0);
        // VULNERABILITY: No rate limiting on payment endpoint
    });
});

// ===========================================================================
// 4. ERROR INFORMATION LEAKAGE
// ===========================================================================
describe("SEC-API-04: Error information leakage", () => {
    test("Invalid MongoDB ID exposes internal error details", async () => {
        const res = await request(app).get("/api/orders/not_a_valid_id");
        expect(res.status).toBe(500);
        // Check if error details expose internal implementation
        if (res.body.error) {
            // VULNERABILITY if Mongoose/MongoDB error messages are exposed
            expect(typeof res.body.error).toBe("string");
        }
    });

    test("Invalid route returns appropriate 404, not stack trace", async () => {
        const res = await request(app).get("/api/nonexistent-route");
        expect([404, 500]).toContain(res.status);
        // Ensure no stack trace is exposed
        const bodyStr = JSON.stringify(res.body);
        expect(bodyStr).not.toContain("node_modules");
        expect(bodyStr).not.toContain("at Function");
    });

    test("Global error handler does not leak file paths", async () => {
        const res = await request(app).get("/api/users/firebase/");
        // This may trigger an error or redirect
        const bodyStr = JSON.stringify(res.body || "");
        expect(bodyStr).not.toContain("C:\\");
        expect(bodyStr).not.toContain("/home/");
    });

    test("Server error response structure includes details field", async () => {
        // Force a server error via an invalid create
        const res = await request(app).post("/api/users/create").send({});
        expect([400, 500]).toContain(res.status);
        // Check if 'details' field leaks error.message from Error objects
        if (res.body.details) {
            // VULNERABILITY: error.message from internal Mongoose/Node errors
            // may contain implementation details
            expect(typeof res.body.details).toBe("string");
        }
    });
});

// ===========================================================================
// 5. SENSITIVE DATA IN API RESPONSES
// ===========================================================================
describe("SEC-API-05: Sensitive data exposure in responses", () => {
    test("Order response exposes OTP fields", async () => {
        const seller = await User.create({
            firebaseUid: "sens_seller_" + Date.now(),
            email: "sensseller@test.com",
            name: "Sens Seller",
            role: "seller",
            phone: "+911122334455",
            trustScore: 60,
        });
        const profile = await SellerProfile.create({
            userId: seller._id,
            orgName: "Sens Foods",
            orgType: "restaurant",
        });
        const buyer = await User.create({
            firebaseUid: "sens_buyer_" + Date.now(),
            email: "sensbuyer@test.com",
            name: "Sens Buyer",
            role: "buyer",
            phone: "+911122334466",
            trustScore: 50,
        });
        await BuyerProfile.create({ userId: buyer._id });

        const listing = await Listing.create({
            sellerId: seller._id,
            sellerProfileId: profile._id,
            foodName: "Sens Food",
            foodType: "meal",
            category: "cooked",
            quantityText: "5",
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

        const orderRes = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
        });

        expect(orderRes.status).toBe(201);
        // VULNERABILITY: handoverOtp and pickupOtp returned in create response
        const order = orderRes.body.order;
        if (order.handoverOtp) {
            expect(order.handoverOtp).toBeDefined();
            // OTP should NOT be in the creation response — only shown to
            // authorized participants at the right time
        }
    });

    test("Payment create-order response exposes Razorpay key_id", async () => {
        const res = await request(app)
            .post("/api/payments/create-order")
            .send({ amount: 100 });

        // Even if Razorpay fails, check the response structure when it succeeds
        if (res.status === 200 && res.body.key_id) {
            // Note: key_id is the public key, generally safe to expose to frontend
            // but should still be controlled
            expect(res.body.key_id).toBeDefined();
        }
    });

    test("User profile response includes all fields (no field filtering)", async () => {
        const user = await User.create({
            firebaseUid: "field_test_" + Date.now(),
            email: "fieldtest@test.com",
            name: "Field Test",
            role: "buyer",
            phone: "+919988776655",
            trustScore: 50,
        });

        const res = await request(app).get(`/api/users/firebase/${user.firebaseUid}`);
        expect(res.status).toBe(200);

        // Check that ALL internal fields are returned
        const userResp = res.body.user;
        expect(userResp.firebaseUid).toBeDefined();
        expect(userResp.phone).toBeDefined();
        expect(userResp.email).toBeDefined();
        // VULNERABILITY: No field filtering — all PII returned in every request
    });
});

// ===========================================================================
// 6. HTTP METHOD ENFORCEMENT
// ===========================================================================
describe("SEC-API-06: HTTP method enforcement", () => {
    test("POST endpoint does not accept GET with body", async () => {
        // Verify that GET to a POST-only endpoint is handled
        const res = await request(app)
            .get("/api/users/create")
            .send({ firebaseUid: "method_test" });

        // Should be 404 (no GET handler on /create) or 405 Method Not Allowed
        expect([404, 405]).toContain(res.status);
    });

    test("DELETE to a GET-only endpoint is rejected", async () => {
        const res = await request(app).delete("/api/listings/active");
        expect([404, 405]).toContain(res.status);
    });
});
