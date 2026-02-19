const User = require("../models/User");
const SellerProfile = require("../models/SellerProfile");
const BuyerProfile = require("../models/BuyerProfile");
const VolunteerProfile = require("../models/VolunteerProfile");

// ======================================================
// CREATE USER
// ======================================================

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
      businessName,
      businessType,
      fssaiNumber,
      fssaiCertificateUrl,
      transportMode,
      dateOfBirth,
      language,
      uiMode
    } = req.body;

    // Validate required fields
    if (!firebaseUid || !email || !role) {
      return res.status(400).json({
        error: "firebaseUid, email, and role are required",
        received: {
          firebaseUid: !!firebaseUid,
          email: !!email,
          role: !!role
        }
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ firebaseUid });
    if (existingUser) {
      return res.status(200).json({
        message: "User already exists",
        user: existingUser
      });
    }

    // Parse location (if GeoJSON object)
    let geoData = null;
    let addressText = location;

    if (location && typeof location === "object") {
      if (
        location.coordinates &&
        Array.isArray(location.coordinates) &&
        location.coordinates.length === 2
      ) {
        geoData = {
          type: "Point",
          coordinates: location.coordinates
        };
        addressText = location.address || location.addressText || "";
      }
    }

    const userData = {
      firebaseUid,
      email,
      name,
      role,
      phone,
      language: language || "en",
      uiMode: uiMode || "standard",
      addressText: addressText || "Not specified",
      emailVerified: false,
      phoneVerified: false
    };

    if (geoData) {
      userData.geo = geoData;
    }

    // Trust score only for seller & volunteer
    if (role === "seller" || role === "volunteer") {
      userData.trustScore = 50;
    }

    const newUser = await User.create(userData);

    // --------------------------------------------------
    // Create role-specific profile
    // --------------------------------------------------

    let profile = null;

    if (role === "seller") {
      const normalizedBusinessType = businessType
        ? businessType.toLowerCase().replace(/ /g, "_")
        : "other";

      const sellerData = {
        userId: newUser._id,
        orgName: businessName || name,
        orgType: normalizedBusinessType,
        fssai: {
          number: fssaiNumber || "",
          certificateUrl: fssaiCertificateUrl || "",
          verified: false
        }
      };

      if (geoData) {
        sellerData.businessGeo = geoData;
        sellerData.businessAddressText = addressText;
      }

      profile = await SellerProfile.create(sellerData);

    } else if (role === "buyer") {
      profile = await BuyerProfile.create({
        userId: newUser._id
      });

    } else if (role === "volunteer") {
      const normalizedTransportMode = transportMode
        ? transportMode.toLowerCase()
        : "walk";

      const volunteerData = {
        userId: newUser._id,
        transportMode: normalizedTransportMode
      };

      if (dateOfBirth) {
        const dob = new Date(dateOfBirth);
        const age = Math.floor(
          (Date.now() - dob.getTime()) /
          (365.25 * 24 * 60 * 60 * 1000)
        );

        if (age >= 18) {
          volunteerData.ageVerification = {
            ageVerified: true,
            verifiedAt: new Date(),
            method: "self_declaration"
          };
        }
      }

      profile = await VolunteerProfile.create(volunteerData);
    }

    return res.status(201).json({
      user: newUser,
      profile,
      message: "User and profile created successfully"
    });

  } catch (error) {
    console.error("Create User Error:", error);
    return res.status(500).json({
      error: "Server error while creating user",
      details: error.message
    });
  }
};


// ======================================================
// GET USER BY FIREBASE UID
// ======================================================

exports.getUserByFirebaseUid = async (req, res) => {
  try {
    const { uid } = req.params;

    const user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    let profile = null;

    if (user.role === "seller") {
      profile = await SellerProfile.findOne({ userId: user._id });
    } else if (user.role === "buyer") {
      profile = await BuyerProfile.findOne({ userId: user._id });
    } else if (user.role === "volunteer") {
      profile = await VolunteerProfile.findOne({ userId: user._id });
    }

    return res.status(200).json({ user, profile });

  } catch (error) {
    return res.status(500).json({
      error: "Server error",
      details: error.message
    });
  }
};

// ======================================================
// GET USER PREFERENCES
// ======================================================

exports.getPreferences = async (req, res) => {
  try {
    const { uid } = req.params;
    const user = await User.findOne({ firebaseUid: uid });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    // Return default preferences if not set
    const preferences = {
      language: user.language || 'en',
      uiMode: user.uiMode || 'standard'
    };

    return res.status(200).json({ preferences });
  } catch (error) {
    return res.status(500).json({ error: "Server error", details: error.message });
  }
};

// ======================================================
// UPDATE USER PREFERENCES
// ======================================================

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

    return res.status(200).json({
      user,
      message: "Preferences updated successfully"
    });

  } catch (error) {
    return res.status(500).json({
      error: "Server error",
      details: error.message
    });
  }
};

// ======================================================
// UPDATE VOLUNTEER PROFILE
// ======================================================

exports.updateVolunteerProfile = async (req, res) => {
  try {
    const { uid } = req.params;
    const { name, phone, addressText, transportMode } = req.body;

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (user.role !== "volunteer") {
      return res.status(400).json({ error: "User is not a volunteer" });
    }

    const validTransportModes = ["walk", "cycle", "bike", "car"];
    const normalizedTransport = transportMode
      ? transportMode.toLowerCase().trim()
      : null;

    if (
      normalizedTransport &&
      !validTransportModes.includes(normalizedTransport)
    ) {
      return res.status(400).json({
        error: "Invalid transport mode",
        allowed: validTransportModes
      });
    }

    const userUpdates = {};
    if (typeof name === "string") userUpdates.name = name.trim();
    if (typeof phone === "string") userUpdates.phone = phone.trim();
    if (typeof addressText === "string") userUpdates.addressText = addressText.trim();

    if (Object.keys(userUpdates).length > 0) {
      await User.findByIdAndUpdate(user._id, { $set: userUpdates });
    }

    const profileUpdates = {};
    if (normalizedTransport) {
      profileUpdates.transportMode = normalizedTransport;
    }

    let updatedProfile = await VolunteerProfile.findOne({ userId: user._id });

    if (!updatedProfile) {
      updatedProfile = await VolunteerProfile.create({
        userId: user._id,
        transportMode: normalizedTransport || "walk"
      });
    } else if (Object.keys(profileUpdates).length > 0) {
      updatedProfile = await VolunteerProfile.findOneAndUpdate(
        { userId: user._id },
        { $set: profileUpdates },
        { new: true }
      );
    }

    const updatedUser = await User.findById(user._id);

    return res.status(200).json({
      message: "Volunteer profile updated successfully",
      user: updatedUser,
      profile: updatedProfile
    });
  } catch (error) {
    return res.status(500).json({
      error: "Server error",
      details: error.message
    });
  }
};

exports.updateBuyerProfile = async (req, res) => {
  try {
    const { uid } = req.params;
    const { name, addressText, gender, dietaryPreferences } = req.body;

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (user.role !== "buyer") {
      return res.status(400).json({ error: "User is not a buyer" });
    }

    const userUpdates = {};
    if (typeof name === "string") userUpdates.name = name.trim();
    if (typeof addressText === "string") userUpdates.addressText = addressText.trim();
    if (typeof gender === "string") userUpdates.gender = gender.trim();

    if (Object.keys(userUpdates).length > 0) {
      await User.findByIdAndUpdate(user._id, { $set: userUpdates });
    }

    const profileUpdates = {};
    if (Array.isArray(dietaryPreferences)) {
      profileUpdates.dietaryPreferences = dietaryPreferences;
    }

    let updatedProfile = await BuyerProfile.findOne({ userId: user._id });

    if (!updatedProfile) {
      updatedProfile = await BuyerProfile.create({ userId: user._id });
    } else if (Object.keys(profileUpdates).length > 0) {
      updatedProfile = await BuyerProfile.findOneAndUpdate(
        { userId: user._id },
        { $set: profileUpdates },
        { new: true }
      );
    }

    const updatedUser = await User.findById(user._id);

    return res.status(200).json({
      message: "Buyer profile updated successfully",
      user: updatedUser,
      profile: updatedProfile
    });
  } catch (error) {
    return res.status(500).json({
      error: "Server error",
      details: error.message
    });
  }
};

exports.updateSellerProfile = async (req, res) => {
  try {
    const { uid } = req.params;
    const { name, phone, addressText, orgName, fssaiNumber, pickupHours } = req.body;

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    if (user.role !== "seller") {
      return res.status(400).json({ error: "User is not a seller" });
    }

    const userUpdates = {};
    if (typeof name === "string") userUpdates.name = name.trim();
    if (typeof phone === "string") userUpdates.phone = phone.trim();
    if (typeof addressText === "string") userUpdates.addressText = addressText.trim();

    if (Object.keys(userUpdates).length > 0) {
      await User.findByIdAndUpdate(user._id, { $set: userUpdates });
    }

    const SellerProfile = require("../models/SellerProfile");

    const profileUpdates = {};
    if (typeof orgName === "string") profileUpdates.orgName = orgName.trim();
    if (typeof fssaiNumber === "string") profileUpdates["fssai.number"] = fssaiNumber.trim();
    if (typeof pickupHours === "string") profileUpdates.pickupHours = pickupHours.trim();

    let updatedProfile = await SellerProfile.findOne({ userId: user._id });

    if (!updatedProfile) {
      updatedProfile = await SellerProfile.create({
        userId: user._id,
        orgName: orgName || "Your Business",
        orgType: "restaurant",
        pickupHours: pickupHours || "09:00 AM - 09:00 PM"
      });
    } else if (Object.keys(profileUpdates).length > 0) {
      updatedProfile = await SellerProfile.findOneAndUpdate(
        { userId: user._id },
        { $set: profileUpdates },
        { new: true }
      );
    }

    const updatedUser = await User.findById(user._id);

    return res.status(200).json({
      message: "Seller profile updated successfully",
      user: updatedUser,
      profile: updatedProfile
    });
  } catch (error) {
    return res.status(500).json({
      error: "Server error",
      details: error.message
    });
  }
};

// ======================================================
// TOGGLE FAVOURITE LISTING
// ======================================================

exports.toggleFavoriteListing = async (req, res) => {
  try {
    const { uid } = req.params;
    const { listingId } = req.body;

    if (!listingId) {
      return res.status(400).json({ error: "listingId is required" });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    let profile = await BuyerProfile.findOne({ userId: user._id });
    if (!profile) {
      profile = await BuyerProfile.create({ userId: user._id });
    }

    const listingIndex = profile.favouriteListings.indexOf(listingId);
    let isFavorited = false;

    if (listingIndex > -1) {
      profile.favouriteListings.splice(listingIndex, 1);
    } else {
      profile.favouriteListings.push(listingId);
      isFavorited = true;
    }

    await profile.save();

    return res.status(200).json({
      message: isFavorited ? "Listing favorited" : "Listing unfavorited",
      isFavorited,
      favouriteListings: profile.favouriteListings
    });
  } catch (error) {
    return res.status(500).json({
      error: "Server error toggle favorite",
      details: error.message
    });
  }
};
