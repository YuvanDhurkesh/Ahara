const express = require('express');
const router = express.Router();
const { createOrder, verifyPayment } = require('../controllers/paymentController');

// Initialize payment (create Razorpay order)
router.post('/create-order', createOrder);

// Verify payment signature
router.post('/verify', verifyPayment);

module.exports = router;
