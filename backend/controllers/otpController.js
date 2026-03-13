const Otp = require("../models/Otp");
const User = require("../models/User");

// Set up Twilio if credentials exist, otherwise use a mock function
const twilioSid = process.env.TWILIO_ACCOUNT_SID;
const twilioAuthToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhoneNumber = process.env.TWILIO_PHONE_NUMBER;

let client;
if (twilioSid && twilioAuthToken) {
  client = require('twilio')(twilioSid, twilioAuthToken);
}

// ======================================================
// SEND OTP
// ======================================================

exports.sendOtp = async (req, res) => {
  try {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      return res.status(400).json({ error: "Phone number is required" });
    }

    // Generate 6-digit OTP
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 mins from now

    // Upsert OTP in DB
    await Otp.findOneAndUpdate(
      { phoneNumber },
      { otp: otpCode, expiresAt },
      { upsert: true, new: true }
    );

    // 🚀 LOG OTP TO CONSOLE (Always do this for easier debugging/bypass)
    console.log(`-----------------------------------------`);
    console.log(`🔑 OTP generated for ${phoneNumber}: ${otpCode}`);
    console.log(`-----------------------------------------`);

    // Send via Twilio if configured
    if (client && twilioPhoneNumber) {
      try {
        console.log(`📡 Attempting to send SMS to ${phoneNumber} via Twilio...`);
        await client.messages.create({
          body: `Your Aahara verification code is: ${otpCode}. It expires in 5 minutes.`,
          from: twilioPhoneNumber,
          to: phoneNumber.startsWith('+') ? phoneNumber : `+91${phoneNumber}` // Assume India (+91) if no country code
        });
        console.log(`✅ OTP sent successfully via Twilio to ${phoneNumber}`);
      } catch (twilioErr) {
        console.error("❌ TWILIO ERROR DETAILS:", {
          message: twilioErr.message,
          code: twilioErr.code,
          moreInfo: twilioErr.moreInfo,
          status: twilioErr.status
        });

        const isLimitError = twilioErr.message.includes("exceeded the 50 daily messages limit");
        const isVerifiedError = twilioErr.message.includes("is not a verified caller ID");

        if (isLimitError || isVerifiedError) {
          console.warn(`⚠️ Twilio failed but allowing "Mock Mode" for testing.`);
          return res.status(200).json({
            message: "Twilio limit reached. Using Mock Mode.",
            phoneNumber,
            otp: otpCode,
            isMockMode: true,
            warning: isLimitError ? "Daily SMS limit exceeded." : "Phone number not verified in Twilio."
          });
        }

        return res.status(500).json({
          error: "Failed to send SMS via Twilio",
          details: twilioErr.message,
          isTrialError: isVerifiedError
        });
      }
    } else {
      console.log(`⚠️ TWILIO NOT CONFIGURED. MOCK OTP for ${phoneNumber}: ${otpCode}`);
    }

    res.status(200).json({
      message: "OTP sent successfully",
      phoneNumber,
      ...(client ? {} : { otp: otpCode })
    });

  } catch (error) {
    console.error("Error in sendOtp:", error);
    res.status(500).json({ error: "Failed to send OTP", details: error.message });
  }
};

// ======================================================
// VERIFY OTP
// ======================================================

exports.verifyOtp = async (req, res) => {
  try {
    const { phoneNumber, otp } = req.body;

    if (!phoneNumber || !otp) {
      return res.status(400).json({ error: "Phone number and OTP are required" });
    }

    // Find the record
    const otpRecord = await Otp.findOne({ phoneNumber });

    if (!otpRecord) {
      return res.status(400).json({ error: "OTP not found or expired. Please request a new one." });
    }

    if (otpRecord.otp !== otp) {
      return res.status(400).json({ error: "Invalid verification code" });
    }

    // OTP matches!
    // Check if user already exists
    const user = await User.findOne({ phone: phoneNumber });

    let profile = null;

    // Mark user's phone as verified if they exist
    if (user) {
      user.phoneVerified = true;
      await user.save();

      // Fetch corresponding profile
      const BuyerProfile = require("../models/BuyerProfile");
      const SellerProfile = require("../models/SellerProfile");
      const VolunteerProfile = require("../models/VolunteerProfile");

      if (user.role === "buyer") {
        profile = await BuyerProfile.findOne({ user: user._id });
      } else if (user.role === "seller") {
        profile = await SellerProfile.findOne({ user: user._id });
      } else if (user.role === "volunteer") {
        profile = await VolunteerProfile.findOne({ user: user._id });
      }
    }

    // Delete used OTP
    await Otp.deleteOne({ _id: otpRecord._id });

    res.status(200).json({
      message: "Phone number verified successfully",
      isExistingUser: !!user,
      user: user || null,
      profile: profile || null
    });

  } catch (error) {
    console.error("Error in verifyOtp:", error);
    res.status(500).json({ error: "Failed to verify OTP", details: error.message });
  }
};
