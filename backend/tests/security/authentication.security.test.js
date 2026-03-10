/**
 * SECURITY TEST SUITE: Authentication & Session Security
 *
 * Tests for:
 * - Missing authentication on protected endpoints
 * - Firebase UID spoofing / impersonation
 * - OTP brute-force susceptibility
 * - OTP reuse prevention
 * - Token / credential exposure in responses
 */

const request = require("supertest");
const app = require("../../server");
const { connect, disconnect } = require("../setup");
const User = require("../../models/User");
const Otp = require("../../models/Otp");

beforeAll(async () => await connect(), 90000);
afterEach(async () => {
    await User.deleteMany({});
    await Otp.deleteMany({});
});
afterAll(async () => await disconnect(), 30000);

// ---------------------------------------------------------------------------
// Helper: create a test user in the DB
// ---------------------------------------------------------------------------
async function seedUser(overrides = {}) {
    return User.create({
        firebaseUid: overrides.firebaseUid || "sec_test_uid_" + Date.now(),
        email: overrides.email || "sectest@test.com",
        name: overrides.name || "Security Tester",
        role: overrides.role || "buyer",
        phone: overrides.phone || "+911234567890",
        trustScore: 50,
    });
}

// ===========================================================================
// 1. UNAUTHENTICATED ACCESS TO PROTECTED RESOURCES
// ===========================================================================
describe("SEC-AUTH-01: Unauthenticated access to protected endpoints", () => {
    let testUser;

    beforeEach(async () => {
        testUser = await seedUser();
    });

    test("GET /api/users/firebase/:uid — accessible without auth header", async () => {
        const res = await request(app).get(`/api/users/firebase/${testUser.firebaseUid}`);
        // FINDING: endpoint returns user data without any auth token
        expect(res.status).toBe(200);
        expect(res.body.user).toBeDefined();
        // VULNERABILITY: No Authorization header required
    });

    test("PUT /api/users/:uid/preferences — modifiable without auth", async () => {
        const res = await request(app)
            .put(`/api/users/${testUser.firebaseUid}/preferences`)
            .send({ language: "hi" });
        expect(res.status).toBe(200);
        // VULNERABILITY: Any user can change any other user's preferences
    });

    test("GET /api/notifications/user/:userId — data leak without auth", async () => {
        const res = await request(app).get(`/api/notifications/user/${testUser._id}`);
        expect(res.status).toBe(200);
        // VULNERABILITY: Anyone can read any user's notifications
    });

    test("POST /api/orders/create — order creation without auth", async () => {
        const res = await request(app)
            .post("/api/orders/create")
            .send({ listingId: "000000000000000000000000", buyerId: testUser._id, quantityOrdered: 1, fulfillment: "self_pickup" });
        // We expect a 400 because listing won't exist, but critically the
        // endpoint did NOT reject the request for missing auth.
        expect([400, 404, 500]).toContain(res.status);
        // VULNERABILITY: No auth check before business-logic validation
    });

    test("POST /api/payments/create-order — payment endpoint without auth", async () => {
        const res = await request(app)
            .post("/api/payments/create-order")
            .send({ amount: 100 });
        // The endpoint processes the request (may fail on Razorpay key),
        // but does NOT reject for missing authentication.
        expect([200, 400, 500]).toContain(res.status);
    });
});

// ===========================================================================
// 2. FIREBASE UID SPOOFING / IMPERSONATION
// ===========================================================================
describe("SEC-AUTH-02: Firebase UID spoofing", () => {
    let victimUser;

    beforeEach(async () => {
        victimUser = await seedUser({ firebaseUid: "victim_uid_123", name: "Victim" });
    });

    test("Attacker can read victim's profile with known UID", async () => {
        const res = await request(app).get(`/api/users/firebase/victim_uid_123`);
        expect(res.status).toBe(200);
        expect(res.body.user.name).toBe("Victim");
        // VULNERABILITY: No server-side Firebase token verification
    });

    test("Attacker can update victim's volunteer profile with known UID", async () => {
        // First change victim to volunteer role for this test
        await User.findByIdAndUpdate(victimUser._id, { role: "volunteer" });

        const res = await request(app)
            .put(`/api/users/victim_uid_123/volunteer-profile`)
            .send({ name: "Hacked Name", transportMode: "car" });

        expect(res.status).toBe(200);
        // VULNERABILITY: Profile modified without verifying caller's identity
    });

    test("Attacker can read victim's notifications with known userId", async () => {
        const res = await request(app).get(`/api/notifications/user/${victimUser._id}`);
        expect(res.status).toBe(200);
        // VULNERABILITY: Notifications are sensitive — no ownership check
    });
});

// ===========================================================================
// 3. OTP BRUTE-FORCE SUSCEPTIBILITY
// ===========================================================================
describe("SEC-AUTH-03: OTP brute-force protection", () => {
    const testPhone = "+919876500001";

    beforeEach(async () => {
        // Seed a valid OTP
        await Otp.create({
            phoneNumber: testPhone,
            otp: "123456",
            expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        });
    });

    test("Multiple incorrect OTP attempts are NOT rate-limited", async () => {
        const attempts = [];
        // Attempt 20 rapid-fire wrong OTPs
        for (let i = 0; i < 20; i++) {
            attempts.push(
                request(app)
                    .post("/api/otp/verify")
                    .send({ phoneNumber: testPhone, otp: String(100000 + i) })
            );
        }

        const results = await Promise.all(attempts);
        const allProcessed = results.every((r) => r.status === 400);
        expect(allProcessed).toBe(true);
        // VULNERABILITY: All 20 attempts processed without lockout or delay.
        // An attacker could iterate all 900,000 combinations.
    });

    test("Correct OTP still works after many failed attempts", async () => {
        // Fire 10 wrong attempts
        for (let i = 0; i < 10; i++) {
            await request(app)
                .post("/api/otp/verify")
                .send({ phoneNumber: testPhone, otp: "000000" });
        }

        // Now try the correct one — should still succeed
        const res = await request(app)
            .post("/api/otp/verify")
            .send({ phoneNumber: testPhone, otp: "123456" });

        expect(res.status).toBe(200);
        // VULNERABILITY: No failed-attempt counter; brute force is viable
    });
});

// ===========================================================================
// 4. OTP REUSE PREVENTION
// ===========================================================================
describe("SEC-AUTH-04: OTP reuse prevention", () => {
    const testPhone = "+919876500002";

    beforeEach(async () => {
        await Otp.create({
            phoneNumber: testPhone,
            otp: "654321",
            expiresAt: new Date(Date.now() + 5 * 60 * 1000),
        });
    });

    test("OTP is deleted after successful verification (no reuse)", async () => {
        // First verification — should succeed
        const res1 = await request(app)
            .post("/api/otp/verify")
            .send({ phoneNumber: testPhone, otp: "654321" });
        expect(res1.status).toBe(200);

        // Second verification with same OTP — should fail
        const res2 = await request(app)
            .post("/api/otp/verify")
            .send({ phoneNumber: testPhone, otp: "654321" });
        expect(res2.status).toBe(400);
        // PASS: OTP deleted after first use (controller calls findByIdAndDelete)
    });
});

// ===========================================================================
// 5. SENSITIVE DATA EXPOSURE IN OTP RESPONSE
// ===========================================================================
describe("SEC-AUTH-05: OTP exposure in API response", () => {
    test("sendOtp returns OTP in response when Twilio is not configured", async () => {
        const res = await request(app)
            .post("/api/otp/send")
            .send({ phoneNumber: "+919876500003" });

        // In test environment, Twilio may fail (500) or succeed without sending SMS (200)
        expect([200, 500]).toContain(res.status);

        // If 200 and Twilio is not configured, the OTP is returned in the body.
        // This is a significant security concern if this codepath reaches production.
        if (res.status === 200 && res.body.otp) {
            // VULNERABILITY: OTP leaked in HTTP response
            expect(res.body.otp).toBeDefined();
            expect(res.body.otp).toHaveLength(6);
        }
    });
});

// ===========================================================================
// 6. USER CREATION WITHOUT VALIDATION
// ===========================================================================
describe("SEC-AUTH-06: User creation input validation", () => {
    test("User created with minimal fields — no email format validation", async () => {
        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "test_uid_" + Date.now(),
            email: "not_an_email",
            role: "buyer",
            name: "Test",
            phone: "123",
        });
        expect(res.status).toBe(201);
        // VULNERABILITY: No email format validation at backend
    });

    test("User created with invalid role is rejected by enum constraint", async () => {
        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "test_uid_invalid_role",
            email: "test@test.com",
            role: "admin",
            name: "Admin Attempt",
            phone: "+911234567890",
        });
        // Mongoose enum should reject "admin"
        expect([400, 500]).toContain(res.status);
    });
});
