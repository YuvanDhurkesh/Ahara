const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Create
router.post('/create', orderController.createOrder);

// Volunteer Actions
router.get('/open', orderController.getOpenOrders);
router.put('/:orderId/accept', orderController.acceptOrder);
router.put('/:orderId/status', orderController.updateStatus);

// User Queries
router.get('/my-orders', orderController.getUserOrders);

// Buyer Actions (Confirm & Reward)
router.put('/:orderId/confirm', orderController.confirmDelivery);

module.exports = router;
