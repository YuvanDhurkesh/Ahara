const User = require("../models/User");
const SellerProfile = require("../models/SellerProfile");
const BuyerProfile = require("../models/BuyerProfile");
const VolunteerProfile = require("../models/VolunteerProfile");

exports.createUser = async (req, res) => {
  try {
    console.log("Incoming body:", req.body);

    const {
      firebaseUid,
      email,
      name,
      role,
      phone,
      location,
      // Seller-specific
      businessName,
      businessType,
      fssaiNumber,
      fssaiCertificateUrl,
      // Volunteer-specific
      transportMode,
      dateOfBirth
    } = req.body;

    // Validate required fields
    if (!firebaseUid || !email || !role) {
      console.error("Validation failed:", { firebaseUid, email, role });
      return res.status(400).json({
        error: "firebaseUid, email, and role are required",
        received: { firebaseUid: !!firebaseUid, email: !!email, role: !!role }
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ firebaseUid });

    if (existingUser) {
      return res.status(200).json(existingUser);
    }

    // Parse location if it's a string (for backward compatibility)
    let geoData = null;
    let addressText = location;

    if (location && typeof location === 'object') {
      // If location is already an object with coordinates
      if (location.coordinates && Array.isArray(location.coordinates) && location.coordinates.length === 2) {
        geoData = {
          type: "Point",
          coordinates: location.coordinates
        };
        addressText = location.address || location.addressText || "";
      }
    }

    // Create User document
    const userData = {
      firebaseUid,
      email,
      name,
      role,
      phone,
      language: req.body.language || "en",
      uiMode: req.body.uiMode || "standard",
      addressText: addressText || "Not specified",
      emailVerified: false,
      phoneVerified: false
    };

    // Add geo if available
    if (geoData) {
      userData.geo = geoData;
    }

    // Set trustScore for seller/volunteer (50), buyers don't get trustScore
    if (role === "seller" || role === "volunteer") {
      userData.trustScore = 50;
    }

    const newUser = await User.create(userData);
    console.log("User created:", newUser._id);

    // Create role-specific profile
    let profile = null;

    if (role === "seller") {
      // Convert businessType to match schema enum (lowercase with underscores)
      const normalizedBusinessType = businessType
        ? businessType.toLowerCase().replace(/ /g, "_")
        : "other";

      // Create SellerProfile
      const sellerData = {
        userId: newUser._id,
        orgName: businessName || name, // Fallback to user name if no business name
        orgType: normalizedBusinessType,
        fssai: {
          number: fssaiNumber || "",
          certificateUrl: fssaiCertificateUrl || "",
          verified: false
        }
      };

      // Add business location if we have coordinates
      if (geoData && geoData.coordinates && geoData.coordinates.length === 2) {
        sellerData.businessGeo = geoData;
        sellerData.businessAddressText = addressText;
      } else if (addressText) {
        // Just store the address text without geo
        sellerData.businessAddressText = addressText;
      }

      profile = await SellerProfile.create(sellerData);
      console.log("SellerProfile created:", profile._id);

    } else if (role === "buyer") {
      // Create BuyerProfile
      profile = await BuyerProfile.create({
        userId: newUser._id
      });
      console.log("BuyerProfile created:", profile._id);

    } else if (role === "volunteer") {
      // Convert transportMode to lowercase to match schema enum
      const normalizedTransportMode = transportMode
        ? transportMode.toLowerCase()
        : "walk";

      // Create VolunteerProfile
      const volunteerData = {
        userId: newUser._id,
        transportMode: normalizedTransportMode
      };

      // Age verification based on DOB
      if (dateOfBirth) {
        const dob = new Date(dateOfBirth);
        const age = Math.floor((Date.now() - dob.getTime()) / (365.25 * 24 * 60 * 60 * 1000));

        if (age >= 18) {
          volunteerData.ageVerification = {
            ageVerified: true,
            verifiedAt: new Date(),
            method: "self_declaration"
          };
        }
      }

      profile = await VolunteerProfile.create(volunteerData);
      console.log("VolunteerProfile created:", profile._id);
    }

    // Return user with profile reference
    res.status(201).json({
      user: newUser,
      profile: profile,
      message: "User and profile created successfully"
    });

  } catch (error) {
    console.error("Create User Error:", error);
    res.status(500).json({
      error: "Server error while creating user",
      details: error.message
    });
  }
};

exports.getUserByFirebaseUid = async (req, res) => {
  try {
    const { uid } = req.params;
    const user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Also find their profile
    let profile = null;
    if (user.role === 'seller') {
      profile = await SellerProfile.findOne({ userId: user._id });
    } else if (user.role === 'buyer') {
      profile = await BuyerProfile.findOne({ userId: user._id });
    } else if (user.role === 'volunteer') {
      profile = await VolunteerProfile.findOne({ userId: user._id });
    }

    res.status(200).json({ user, profile });
  } catch (error) {
    res.status(500).json({ error: "Server error", details: error.message });
  }
};

exports.updatePreferences = async (req, res) => {
  try {
    const { uid } = req.params;
    const { language, uiMode } = req.body;

    const updates = {};
    if (language) updates.language = language;
    if (uiMode) updates.uiMode = uiMode;

    const user = await User.findOneAndUpdate(
      { firebaseUid: uid },
      { $set: updates },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.status(200).json({ user, message: "Preferences updated successfully" });
  } catch (error) {
    res.status(500).json({ error: "Server error", details: error.message });
  }
};
