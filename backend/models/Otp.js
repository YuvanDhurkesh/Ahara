const mongoose = require("mongoose");

const otpSchema = new mongoose.Schema({
  phoneNumber: {
    type: String,
    required: true,
    index: true
  },
  otp: {
    type: String,
    required: true
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expires: '5m' } // Automatically delete OTP after 5 minutes
  }
}, { timestamps: true });

module.exports = mongoose.model("Otp", otpSchema);
