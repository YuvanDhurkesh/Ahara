const paymentController = require('../../controllers/paymentController');
const httpMocks = require('node-mocks-http');
const crypto = require('crypto');

// Mock Razorpay module
jest.mock('razorpay', () => {
    return jest.fn().mockImplementation(() => ({
        orders: {
            create: jest.fn(),
        },
    }));
});

const Razorpay = require('razorpay');

// ─────────────────────────────────────────────
// createOrder (Razorpay)
// ─────────────────────────────────────────────
describe('Payment Controller - createOrder', () => {
    let req, res;

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should return 400 if amount is missing', async () => {
        req.body = {};

        await paymentController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().success).toBe(false);
    });

    it('should return 400 if amount is zero', async () => {
        req.body = { amount: 0 };

        await paymentController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().success).toBe(false);
    });

    it('should return 400 if amount is negative', async () => {
        req.body = { amount: -100 };

        await paymentController.createOrder(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().success).toBe(false);
    });
});

// ─────────────────────────────────────────────
// verifyPayment
// ─────────────────────────────────────────────
describe('Payment Controller - verifyPayment', () => {
    let req, res;
    const TEST_SECRET = process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret';

    beforeEach(() => {
        req = httpMocks.createRequest();
        res = httpMocks.createResponse();
        jest.clearAllMocks();
    });

    it('should verify a valid payment signature', () => {
        const orderId = 'order_test123';
        const paymentId = 'pay_test456';

        // Generate a valid signature
        const hmac = crypto.createHmac('sha256', TEST_SECRET);
        hmac.update(orderId + '|' + paymentId);
        const validSignature = hmac.digest('hex');

        req.body = {
            razorpay_order_id: orderId,
            razorpay_payment_id: paymentId,
            razorpay_signature: validSignature,
        };

        paymentController.verifyPayment(req, res);

        expect(res.statusCode).toBe(200);
        expect(res._getJSONData().success).toBe(true);
        expect(res._getJSONData().message).toBe('Payment Verified');
    });

    it('should return 400 for an invalid payment signature', () => {
        req.body = {
            razorpay_order_id: 'order_test123',
            razorpay_payment_id: 'pay_test456',
            razorpay_signature: 'invalid_signature_abc123',
        };

        paymentController.verifyPayment(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().success).toBe(false);
        expect(res._getJSONData().message).toBe('Invalid Signature');
    });

    it('should return 400 when signature does not match due to tampered orderId', () => {
        const orderId = 'order_test123';
        const paymentId = 'pay_test456';

        const hmac = crypto.createHmac('sha256', TEST_SECRET);
        hmac.update(orderId + '|' + paymentId);
        const signature = hmac.digest('hex');

        req.body = {
            razorpay_order_id: 'order_tampered',
            razorpay_payment_id: paymentId,
            razorpay_signature: signature,
        };

        paymentController.verifyPayment(req, res);

        expect(res.statusCode).toBe(400);
        expect(res._getJSONData().success).toBe(false);
    });
});
