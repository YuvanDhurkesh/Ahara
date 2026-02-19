const express = require("express");
const router = express.Router();
const otpController = require("../controllers/otpController");

// /api/otp/send
router.post("/send", otpController.sendOtp);

// /api/otp/verify
router.post("/verify", otpController.verifyOtp);

module.exports = router;
