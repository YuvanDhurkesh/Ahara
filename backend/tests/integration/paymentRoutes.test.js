jest.mock('razorpay', () => {
    return jest.fn().mockImplementation(() => {
        return {
            orders: {
                create: jest.fn().mockResolvedValue({ id: 'mock_razorpay_order_id', amount: 50000, currency: 'INR' })
            }
        };
    });
});

const request = require('supertest');
const app = require('../../server');
const crypto = require('crypto');
const { connect, disconnect } = require('../setup');

describe('Payment Routes Integration Tests', () => {
    beforeAll(async () => {
        await connect();
    }, 60000);

    afterAll(async () => {
        await disconnect();
    }, 60000);

    it('POST /api/payments/create-order should create Razorpay order', async () => {
        const res = await request(app)
            .post('/api/payments/create-order')
            .send({ amount: 500, receipt: 'receipt_123' });

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.order.id).toBe('mock_razorpay_order_id');
    });

    it('POST /api/payments/verify should verify valid signature', async () => {
        const razorpay_order_id = 'mock_razorpay_order_id';
        const razorpay_payment_id = 'mock_razorpay_payment_id';
        const key_secret = process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret';

        const hmac = crypto.createHmac('sha256', key_secret);
        hmac.update(razorpay_order_id + "|" + razorpay_payment_id);
        const razorpay_signature = hmac.digest('hex');

        const res = await request(app)
            .post('/api/payments/verify')
            .send({
                razorpay_order_id,
                razorpay_payment_id,
                razorpay_signature
            });

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.message).toBe('Payment Verified');
    });

    it('POST /api/payments/verify should fail with invalid signature', async () => {
        const res = await request(app)
            .post('/api/payments/verify')
            .send({
                razorpay_order_id: 'oid',
                razorpay_payment_id: 'pid',
                razorpay_signature: 'invalid_sig'
            });

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
        expect(res.body.message).toBe('Invalid Signature');
    });
});
