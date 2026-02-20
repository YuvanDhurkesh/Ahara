const express = require("express");
const router = express.Router();
const verificationController = require("../controllers/verificationController");

// /api/verification/aadhaar
router.post("/aadhaar", verificationController.verifyAadhaar);

module.exports = router;
