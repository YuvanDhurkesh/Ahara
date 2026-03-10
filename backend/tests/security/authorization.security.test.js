/**
 * SECURITY TEST SUITE: Authorization & Access Control
 *
 * Tests for:
 * - Broken Access Control (OWASP A01:2021)
 * - Insecure Direct Object Reference (IDOR)
 * - Missing ownership validation
 * - Role-based access control bypass
 * - Horizontal and vertical privilege escalation
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
async function createFullSeller() {
    const user = await User.create({
        firebaseUid: "seller_uid_" + Date.now(),
        email: "seller@test.com",
        name: "Test Seller",
        role: "seller",
        phone: "+911111111111",
        trustScore: 60,
    });
    const profile = await SellerProfile.create({
        userId: user._id,
        orgName: "Test Foods",
        orgType: "restaurant",
    });
    return { user, profile };
}

async function createFullBuyer(suffix = "") {
    const user = await User.create({
        firebaseUid: "buyer_uid_" + suffix + Date.now(),
        email: `buyer${suffix}@test.com`,
        name: "Test Buyer " + suffix,
        role: "buyer",
        phone: `+91222222222${suffix.length ? suffix.slice(0, 1) : "0"}`,
        trustScore: 50,
    });
    await BuyerProfile.create({ userId: user._id });
    return user;
}

async function createListing(seller, sellerProfile) {
    return Listing.create({
        sellerId: seller._id,
        sellerProfileId: sellerProfile._id,
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
}

// ===========================================================================
// 1. IDOR — HORIZONTAL PRIVILEGE ESCALATION (BUYER → BUYER)
// ===========================================================================
describe("SEC-AUTHZ-01: Horizontal privilege escalation between buyers", () => {
    let buyerA, buyerB, seller, sellerProfile, listing;

    beforeEach(async () => {
        const sellerData = await createFullSeller();
        seller = sellerData.user;
        sellerProfile = sellerData.profile;
        buyerA = await createFullBuyer("A");
        buyerB = await createFullBuyer("B");
        listing = await createListing(seller, sellerProfile);
    });

    test("Buyer B can view Buyer A's orders via IDOR", async () => {
        // Create order for Buyer A
        await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyerA._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
        });

        // Buyer B accesses Buyer A's orders by substituting the buyerId
        const res = await request(app).get(`/api/orders/buyer/${buyerA._id}`);
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body)).toBe(true);
        // VULNERABILITY: No ownership check — Buyer B can see Buyer A's orders
    });

    test("Any user can read another user's preferences", async () => {
        await request(app)
            .put(`/api/users/${buyerA.firebaseUid}/preferences`)
            .send({ language: "ta" });

        // Buyer B reads Buyer A's preferences
        const res = await request(app).get(`/api/users/${buyerA.firebaseUid}/preferences`);
        expect(res.status).toBe(200);
        expect(res.body.preferences.language).toBe("ta");
        // VULNERABILITY: No ownership check on preferences endpoint
    });
});

// ===========================================================================
// 2. IDOR — VERTICAL PRIVILEGE ESCALATION (BUYER → SELLER)
// ===========================================================================
describe("SEC-AUTHZ-02: Vertical privilege escalation (buyer acting as seller)", () => {
    let buyer, seller, sellerProfile, listing;

    beforeEach(async () => {
        const sellerData = await createFullSeller();
        seller = sellerData.user;
        sellerProfile = sellerData.profile;
        buyer = await createFullBuyer();
        listing = await createListing(seller, sellerProfile);
    });

    test("Buyer can view seller's order list via IDOR", async () => {
        const res = await request(app).get(`/api/orders/seller/${seller._id}`);
        expect(res.status).toBe(200);
        // VULNERABILITY: No role check on seller-specific endpoint
    });

    test("Buyer can attempt to update a listing they don't own", async () => {
        const res = await request(app)
            .put(`/api/listings/update/${listing._id}`)
            .send({ foodName: "Hacked Food Name" });
        expect(res.status).toBe(200);
        // VULNERABILITY: No ownership verification on listing update
        expect(res.body.listing || res.body.message).toBeDefined();
    });

    test("Buyer can attempt to delete a listing they don't own", async () => {
        const res = await request(app).delete(`/api/listings/delete/${listing._id}`);
        expect([200, 204]).toContain(res.status);
        // VULNERABILITY: No ownership or role check on listing deletion
    });
});

// ===========================================================================
// 3. NOTIFICATION ACCESS CONTROL
// ===========================================================================
describe("SEC-AUTHZ-03: Notification access control", () => {
    let userA, userB;

    beforeEach(async () => {
        userA = await createFullBuyer("notifA");
        userB = await createFullBuyer("notifB");

        // Create a notification for User A
        await Notification.create({
            userId: userA._id,
            type: "order_update",
            title: "Sensitive Notification",
            message: "Your order has personal details",
            data: { orderId: "fake_order_id" },
        });
    });

    test("User B can read User A's notifications", async () => {
        const res = await request(app).get(`/api/notifications/user/${userA._id}`);
        expect(res.status).toBe(200);
        expect(res.body.notifications.length).toBeGreaterThan(0);
        expect(res.body.notifications[0].title).toBe("Sensitive Notification");
        // VULNERABILITY: No authentication/ownership check
    });

    test("User B can mark User A's notifications as read", async () => {
        const notifs = await Notification.find({ userId: userA._id });
        const notifId = notifs[0]._id;

        const res = await request(app)
            .patch(`/api/notifications/${notifId}/read`)
            .send({ userId: userA._id });
        expect(res.status).toBe(200);
        // VULNERABILITY: No caller identity verification
    });

    test("User B can mark ALL of User A's notifications as read", async () => {
        const res = await request(app)
            .patch(`/api/notifications/user/${userA._id}/read-all`);
        expect(res.status).toBe(200);
        // VULNERABILITY: Mass modification without auth
    });
});

// ===========================================================================
// 4. ORDER ACCESS CONTROL
// ===========================================================================
describe("SEC-AUTHZ-04: Order access control", () => {
    let buyer, seller, sellerProfile, listing, order;

    beforeEach(async () => {
        const sellerData = await createFullSeller();
        seller = sellerData.user;
        sellerProfile = sellerData.profile;
        buyer = await createFullBuyer();
        listing = await createListing(seller, sellerProfile);

        const orderRes = await request(app).post("/api/orders/create").send({
            listingId: listing._id,
            buyerId: buyer._id,
            quantityOrdered: 1,
            fulfillment: "self_pickup",
        });
        order = orderRes.body.order;
    });

    test("Unauthenticated user can view any order by ID", async () => {
        const res = await request(app).get(`/api/orders/${order._id}`);
        expect(res.status).toBe(200);
        expect(res.body.handoverOtp).toBeDefined();
        // VULNERABILITY: OTP exposed to any caller — sensitive operational data
    });

    test("Any user can cancel another user's order", async () => {
        const res = await request(app)
            .post(`/api/orders/${order._id}/cancel`)
            .send({ cancelledBy: "buyer", reason: "Attacker cancel" });

        expect([200, 400]).toContain(res.status);
        // If 200, the order was cancelled by an unauthenticated attacker
    });

    test("Any user can update order status", async () => {
        const res = await request(app)
            .patch(`/api/orders/${order._id}/status`)
            .send({ status: "delivered" });

        expect([200, 400, 500]).toContain(res.status);
        // VULNERABILITY: No auth middleware on status update
    });
});

// ===========================================================================
// 5. PROFILE UPDATE ACROSS ROLES
// ===========================================================================
describe("SEC-AUTHZ-05: Cross-role profile update protection", () => {
    test("Non-volunteer cannot update volunteer profile (role check exists)", async () => {
        const buyer = await createFullBuyer("roletest");
        const res = await request(app)
            .put(`/api/users/${buyer.firebaseUid}/volunteer-profile`)
            .send({ transportMode: "bike" });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/not a volunteer/i);
        // PASS: Controller has role check (but no auth check)
    });

    test("Non-buyer cannot update buyer profile (role check exists)", async () => {
        const seller = (await createFullSeller()).user;
        const res = await request(app)
            .put(`/api/users/${seller.firebaseUid}/buyer-profile`)
            .send({ name: "Hacked" });

        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(/not a buyer/i);
        // PASS: Controller has role check (but no auth check)
    });
});

// ===========================================================================
// 6. LISTING SELLER STATS — INFORMATION DISCLOSURE
// ===========================================================================
describe("SEC-AUTHZ-06: Seller stats information disclosure", () => {
    test("Any user can view seller statistics", async () => {
        const { user: seller, profile: sellerProfile } = await createFullSeller();
        await createListing(seller, sellerProfile);

        const res = await request(app)
            .get("/api/listings/seller-stats")
            .query({ sellerId: seller._id.toString() });

        expect(res.status).toBe(200);
        // VULNERABILITY: Business-sensitive seller data exposed without auth
    });
});
