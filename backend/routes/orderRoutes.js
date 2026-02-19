const express = require("express");
const router = express.Router();
const orderController = require("../controllers/orderController");

router.post("/create", orderController.createOrder);
router.get("/volunteer/requests/:volunteerId", orderController.getVolunteerRescueRequests);
router.get("/volunteer/:volunteerId", orderController.getVolunteerOrders);
router.get("/buyer/:buyerId", orderController.getBuyerOrders);
router.get("/seller/:sellerId", orderController.getSellerOrders);
router.get("/:id", orderController.getOrderById);
router.patch("/:id/status", orderController.updateOrderStatus);
router.patch("/:id", orderController.updateOrder);
router.post("/:id/cancel", orderController.cancelOrder);
router.post("/:id/verify-otp", orderController.verifyOtp);
router.post("/:id/accept", orderController.acceptRescueRequest);

module.exports = router;
