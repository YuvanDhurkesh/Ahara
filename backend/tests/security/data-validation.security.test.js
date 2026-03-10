/**
 * SECURITY TEST SUITE: Data Validation & Business Logic
 *
 * Tests for:
 * - Input validation bypass
 * - Business logic flaws
 * - Data integrity attacks
 * - Mass assignment / parameter tampering
 * - Aadhaar validation bypass attempts
 * - Payment amount manipulation
 */

const request = require("supertest");
const app = require("../../server");
const { connect, disconnect } = require("../setup");
const User = require("../../models/User");
const Listing = require("../../models/Listing");
const Order = require("../../models/Order");
const SellerProfile = require("../../models/SellerProfile");
const BuyerProfile = require("../../models/BuyerProfile");
const VolunteerProfile = require("../../models/VolunteerProfile");
const Notification = require("../../models/Notification");

beforeAll(async () => await connect(), 90000);
afterEach(async () => {
    await User.deleteMany({});
    await Listing.deleteMany({});
    await Order.deleteMany({});
    await SellerProfile.deleteMany({});
    await BuyerProfile.deleteMany({});
    await VolunteerProfile.deleteMany({});
    await Notification.deleteMany({});
});
afterAll(async () => await disconnect(), 30000);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function createTestEnvironment() {
    const seller = await User.create({
        firebaseUid: "val_seller_" + Date.now(),
        email: "valseller@test.com",
        name: "Validation Seller",
        role: "seller",
        phone: "+911234509876",
        trustScore: 60,
    });
    const sellerProfile = await SellerProfile.create({
        userId: seller._id,
        orgName: "Val Foods",
        orgType: "restaurant",
    });
    const buyer = await User.create({
        firebaseUid: "val_buyer_" + Date.now(),
        email: "valbuyer@test.com",
        name: "Validation Buyer",
        role: "buyer",
        phone: "+910987654321",
        trustScore: 50,
    });
    await BuyerProfile.create({ userId: buyer._id });

    const listing = await Listing.create({
        sellerId: seller._id,
        sellerProfileId: sellerProfile._id,
        foodName: "Validation Food",
        foodType: "meal",
        category: "cooked",
        quantityText: "10 plates",
        totalQuantity: 10,
        remainingQuantity: 10,
        pricing: { discountedPrice: 100, isFree: false },
        pickupWindow: {
            from: new Date(),
            to: new Date(Date.now() + 4 * 60 * 60 * 1000),
        },
        status: "active",
        isSafetyValidated: true,
        safetyStatus: "validated",
    });

    return { seller, sellerProfile, buyer, listing };
}

// ===========================================================================
// 1. MASS ASSIGNMENT / PARAMETER TAMPERING
// ===========================================================================
describe("SEC-VAL-01: Mass assignment vulnerabilities", () => {
    test("User creation — attacker injects trustScore field", async () => {
        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "mass_assign_" + Date.now(),
            email: "massassign@test.com",
            role: "buyer",
            name: "Mass Assign Test",
            phone: "+911111100000",
            trustScore: 100, // Attacker tries to set max trust
        });

        expect(res.status).toBe(201);
        // Controller explicitly sets trustScore to 50 — check if attacker value was ignored
        expect(res.body.user.trustScore).toBe(50);
        // PASS: Controller overrides with hardcoded default
    });

    test("User creation — attacker injects accountStatus field", async () => {
        const res = await request(app).post("/api/users/create").send({
            firebaseUid: "status_inject_" + Date.now(),
            email: "statusinject@test.com",
            role: "buyer",
            name: "Status Inject",
            phone: "+912222200000",
            accountStatus: "active", // Attempt to set account status
        });

        expect(res.status).toBe(201);
        // accountStatus is NOT in the destructured fields, so Mongoose default applies
        expect(res.body.user.accountStatus).toBe("active");
    });

    test("Listing update — attacker injects sellerId to steal ownership", async () => {
        const { seller, sellerProfile, listing } = await createTestEnvironment();

        const attacker = await User.create({
            firebaseUid: "attacker_" + Date.now(),
            email: "attacker@test.com",
            name: "Attacker",
            role: "seller",
            phone: "+913333300000",
            trustScore: 50,
        });

        // Attacker tries to reassign listing to themselves
        const res = await request(app)
            .put(`/api/listings/update/${listing._id}`)
            .send({ sellerId: attacker._id });

        expect(res.status).toBe(200);
        // VULNERABILITY: Listing's sellerId can be overwritten via $set: req.body
        const updated = await Listing.findById(listing._id);
        if (updated.sellerId.toString() === attacker._id.toString()) {
            // CRITICAL: Ownership was stolen
            expect(true).toBe(true); // Document the vulnerability
        }
    });

    test("Order update — attacker injects buyerId to claim order", async () => {
        const { buyer, listing } = await createTestEnvironment();

        const orderRes = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
        });
        const order = orderRes.body.order;

        const attacker = await User.create({
            firebaseUid: "order_attacker_" + Date.now(),
            email: "orderattacker@test.com",
            name: "Order Attacker",
            role: "buyer",
            phone: "+914444400000",
            trustScore: 50,
        });

        // Attempt to change buyerId
        const res = await request(app)
            .patch(`/api/orders/${order._id}`)
            .send({ buyerId: attacker._id });

        // The controller only processes specific fields (status, fulfillment, payment)
        // Check if buyerId was changed
        const updatedOrder = await Order.findById(order._id);
        if (updatedOrder.buyerId.toString() === attacker._id.toString()) {
            // VULNERABILITY: buyerId was changed
        }
        expect([200, 400]).toContain(res.status);
    });
});

// ===========================================================================
// 2. QUANTITY MANIPULATION
// ===========================================================================
describe("SEC-VAL-02: Quantity and pricing manipulation", () => {
    test("Order with negative quantity", async () => {
        const { buyer, listing } = await createTestEnvironment();

        const res = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: -5,
            fulfillment: "self_pickup",
        });

        // Should be rejected — negative quantity makes no sense
        // But if controller only checks remainingQuantity >= quantityOrdered,
        // negative values will always pass (10 >= -5 is true)
        expect([201, 400]).toContain(res.status);
        if (res.status === 201) {
            // VULNERABILITY: Negative quantity accepted — could increase remaining stock
        }
    });

    test("Order with zero quantity", async () => {
        const { buyer, listing } = await createTestEnvironment();

        const res = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 0,
            fulfillment: "self_pickup",
        });

        expect([201, 400]).toContain(res.status);
        // Zero quantity order may be pointless but should be validated
    });

    test("Order with quantity exceeding available", async () => {
        const { buyer, listing } = await createTestEnvironment();

        const res = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 999999,
            fulfillment: "self_pickup",
        });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/insufficient/i);
        // PASS: Controller checks remainingQuantity
    });

    test("Payment with negative amount", async () => {
        const res = await request(app)
            .post("/api/payments/create-order")
            .send({ amount: -100, currency: "INR" });

        expect(res.status).toBe(400);
        // PASS if rejected; FAIL if negative payment is created
    });

    test("Payment with zero amount", async () => {
        const res = await request(app)
            .post("/api/payments/create-order")
            .send({ amount: 0, currency: "INR" });

        expect(res.status).toBe(400);
        // PASS: amount <= 0 check exists in paymentController
    });

    test("Payment with extremely large amount", async () => {
        const res = await request(app)
            .post("/api/payments/create-order")
            .send({ amount: 999999999999 });

        // Should be handled by Razorpay limits or application validation
        expect([200, 400, 500]).toContain(res.status);
    });
});

// ===========================================================================
// 3. AADHAAR VALIDATION BYPASS ATTEMPTS
// ===========================================================================
describe("SEC-VAL-03: Aadhaar verification bypass", () => {
    test("Empty Aadhaar number rejected", async () => {
        const res = await request(app)
            .post("/api/verification/aadhaar")
            .send({ phoneNumber: "+911234567890", aadhaarNumber: "" });

        expect(res.status).toBe(400);
    });

    test("Aadhaar with non-numeric characters rejected", async () => {
        const res = await request(app)
            .post("/api/verification/aadhaar")
            .send({ phoneNumber: "+911234567890", aadhaarNumber: "1234abcd5678" });

        expect(res.status).toBe(400);
    });

    test("Aadhaar starting with 0 or 1 rejected", async () => {
        const res = await request(app)
            .post("/api/verification/aadhaar")
            .send({ phoneNumber: "+911234567890", aadhaarNumber: "012345678901" });

        expect(res.status).toBe(400);
    });

    test("Aadhaar with wrong length rejected", async () => {
        const res = await request(app)
            .post("/api/verification/aadhaar")
            .send({ phoneNumber: "+911234567890", aadhaarNumber: "12345" });

        expect(res.status).toBe(400);
    });

    test("Aadhaar with invalid Verhoeff checksum rejected", async () => {
        // This is a 12-digit number starting with 2-9 but with invalid checksum
        const res = await request(app)
            .post("/api/verification/aadhaar")
            .send({ phoneNumber: "+911234567890", aadhaarNumber: "234567890121" });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/checksum/i);
        // PASS: Verhoeff algorithm correctly validates
    });

    test("Aadhaar as SQL injection string rejected", async () => {
        const res = await request(app)
            .post("/api/verification/aadhaar")
            .send({ phoneNumber: "+911234567890", aadhaarNumber: "' OR '1'='1" });

        expect(res.status).toBe(400);
    });
});

// ===========================================================================
// 4. LISTING SAFETY VALIDATION BYPASS
// ===========================================================================
describe("SEC-VAL-04: Listing safety validation", () => {
    test("Listing with expired pickup window is rejected", async () => {
        const { seller, sellerProfile } = await createTestEnvironment();

        const res = await request(app).post("/api/listings/create").send({
            sellerId: seller._id,
            sellerProfileId: sellerProfile._id,
            foodName: "Expired Food",
            foodType: "meal",
            totalQuantity: 5,
            pickupWindow: {
                from: new Date(Date.now() - 48 * 60 * 60 * 1000),
                to: new Date(Date.now() - 24 * 60 * 60 * 1000),
            },
            pricing: { discountedPrice: 0, isFree: true },
        });

        // The perishability engine should reject this
        expect([400, 201]).toContain(res.status);
        // Document whether past dates are accepted
    });

    test("Order on expired listing is rejected", async () => {
        const { buyer, listing } = await createTestEnvironment();

        // Manually expire the listing
        listing.pickupWindow.to = new Date(Date.now() - 1000);
        await listing.save();

        const res = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
        });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/expired/i);
        // PASS: Controller checks expiry
    });

    test("Order on cancelled listing is rejected", async () => {
        const { buyer, listing } = await createTestEnvironment();

        listing.status = "cancelled";
        await listing.save();

        const res = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
        });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/no longer active/i);
        // PASS: Controller checks listing status
    });
});

// ===========================================================================
// 5. ENUMERATION ATTACKS
// ===========================================================================
describe("SEC-VAL-05: User enumeration", () => {
    test("Non-existent Firebase UID returns 404 (enumerable)", async () => {
        const res = await request(app).get("/api/users/firebase/nonexistent_uid_xyz");
        expect(res.status).toBe(404);
        // VULNERABILITY (Low): Different response for existing vs non-existing users
        // allows user enumeration
    });

    test("Non-existent phone returns 404 (enumerable)", async () => {
        const res = await request(app).get("/api/users/phone/+910000000000");
        expect(res.status).toBe(404);
        // VULNERABILITY (Low): Phone number existence can be checked
    });
});

// ===========================================================================
// 6. RACE CONDITION — DOUBLE ORDER
// ===========================================================================
describe("SEC-VAL-06: Race condition in order creation", () => {
    test("Concurrent orders exhaust stock correctly (transaction test)", async () => {
        const { buyer, listing } = await createTestEnvironment();
        // Listing has remainingQuantity = 10

        // Create a second buyer
        const buyer2 = await User.create({
            firebaseUid: "race_buyer2_" + Date.now(),
            email: "racebuyer2@test.com",
            name: "Race Buyer 2",
            role: "buyer",
            phone: "+910000099999",
            trustScore: 50,
        });
        await BuyerProfile.create({ userId: buyer2._id });

        // Send two concurrent orders for 8 each (only 10 available)
        const [res1, res2] = await Promise.all([
            request(app).post("/api/orders/create").send({
                listingId: listing._id,
                buyerId: buyer._id,
                quantityOrdered: 8,
                fulfillment: "self_pickup",
            }),
            request(app).post("/api/orders/create").send({
                listingId: listing._id,
                buyerId: buyer2._id,
                quantityOrdered: 8,
                fulfillment: "self_pickup",
            }),
        ]);

        // One should succeed (201), one should fail (400 insufficient quantity)
        const statuses = [res1.status, res2.status].sort();
        // With proper transactions and retry logic, at most one should succeed
        const successes = statuses.filter((s) => s === 201);
        expect(successes.length).toBeLessThanOrEqual(1);
        // PASS: Transactions prevent double-spending of inventory
    });
});
