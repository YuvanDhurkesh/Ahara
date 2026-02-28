const Razorpay = require('razorpay');
const crypto = require('crypto');
require('dotenv').config();

console.log("Razorpay KEY_ID:", process.env.RAZORPAY_KEY_ID);
console.log("Razorpay KEY_SECRET loaded:", !!process.env.RAZORPAY_KEY_SECRET);

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_placeholder',
    key_secret: process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret'
});

// Create Razorpay Order
exports.createOrder = async (req, res) => {
    try {
        const { amount, currency = 'INR', receipt } = req.body;

        // Validate amount
        if (!amount || amount <= 0) {
            return res.status(400).json({ 
                success: false, 
                error: "Invalid amount: " + amount 
            });
        }

        console.log("Creating Razorpay order with amount:", amount);

        const options = {
            amount: Math.round(amount * 100), // Amount in paise
            currency,
            receipt: receipt || `order_${Date.now()}`,
            payment_capture: 1 // Auto capture
        };

        console.log("Razorpay options:", options);
        const order = await razorpay.orders.create(options);
        console.log("Order created successfully:", order.id);

        res.status(200).json({
            success: true,
            order,
            key_id: process.env.RAZORPAY_KEY_ID
        });
    } catch (error) {
        console.error("Razorpay Order Creation Error:", error);
        res.status(500).json({ 
            success: false, 
            error: error.message,
            details: error.metadata || null 
        });
    }
};

// Verify Signature
exports.verifyPayment = (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        const key_secret = process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret';

        const hmac = crypto.createHmac('sha256', key_secret);
        hmac.update(razorpay_order_id + "|" + razorpay_payment_id);
        const generated_signature = hmac.digest('hex');

        if (generated_signature === razorpay_signature) {
            res.status(200).json({ success: true, message: "Payment Verified" });
        } else {
            res.status(400).json({ success: false, message: "Invalid Signature" });
        }
    } catch (error) {
        console.error("Payment Verification Error:", error);
        res.status(500).json({ success: false, error: error.message });
    }
};
