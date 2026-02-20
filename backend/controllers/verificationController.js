const VolunteerProfile = require("../models/VolunteerProfile");
const SellerProfile = require("../models/SellerProfile");
const User = require("../models/User");
const { validateAadhaar } = require("../utils/aadhaarValidator");

// ======================================================
// MOCK AADHAAR VERIFICATION
// ======================================================

exports.verifyAadhaar = async (req, res) => {
  try {
    const { phoneNumber, aadhaarNumber, name } = req.body;

    if (!phoneNumber || !aadhaarNumber) {
      return res.status(400).json({ error: "Phone number and Aadhaar number are required" });
    }

    // Full Verification Logic (Structure + Checksum)
    const validation = validateAadhaar(aadhaarNumber);
    if (!validation.isValid) {
      return res.status(400).json({ error: validation.error });
    }

    // Mock logic: 
    // 1. If it ends in '000', fail it (for testing error scenarios)
    // 2. Otherwise succeed
    if (aadhaarNumber.endsWith("000")) {
      return res.status(400).json({ 
        success: false, 
        error: "Aadhaar verification failed. Proof of identity could not be verified by the mock service." 
      });
    }

    // Success response
    console.log(`✅ MOCK AADHAAR VERIFIED for ${phoneNumber}: ${aadhaarNumber}`);

    // If a user exists with this phone, mark them as verified in their role-specific profile
    const user = await User.findOne({ phone: phoneNumber });
    if (user) {
        if (user.role === "volunteer") {
            let profile = await VolunteerProfile.findOne({ userId: user._id });
            if (profile) {
                profile.verification.idProof = {
                    submitted: true,
                    verified: true,
                    documentUrl: "MOCK_AADHAAR_VERIFIED"
                };
                profile.verification.level = Math.max(profile.verification.level, 1);
                await profile.save();
            }
        } else if (user.role === "seller") {
            let profile = await SellerProfile.findOne({ userId: user._id });
            if (profile) {
                profile.fssai.verified = true; // For now assuming aadhaar verified completes identity
                profile.fssai.certificateUrl = "MOCK_AADHAAR_IDENTITY_VERIFIED";
                await profile.save();
                
                // Update user trust score
                user.trustScore = Math.max(user.trustScore, 60);
                await user.save();
            }
        }
    }

    return res.status(200).json({
      success: true,
      message: "Aadhaar verified successfully via mock service",
      data: {
        lastFour: aadhaarNumber.slice(-4),
        status: "verified",
        timestamp: new Date().toISOString()
      }
    });

  } catch (error) {
    console.error("Error in verifyAadhaar:", error);
    res.status(500).json({ error: "Failed to verify Aadhaar", details: error.message });
  }
};
