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
      dateOfBirth
    } = req.body;

    // Validate required fields
    if (!firebaseUid || !email || !role) {
      return res.status(400).json({
        error: "firebaseUid, email, and role are required",
        received: { firebaseUid: !!firebaseUid, email: !!email, role: !!role }
      });
    }

    const existingUser = await User.findOne({ firebaseUid });
    if (existingUser) {
      return res.status(200).json(existingUser);
    }

    // Parse location
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
      language: req.body.language || "en",
      addressText: addressText || "Not specified",
      emailVerified: false,
      phoneVerified: false
    };

    if (geoData) {
      userData.geo = geoData;
    }

    if (role === "seller" || role === "volunteer") {
      userData.trustScore = 50;
    }

    const newUser = await User.create(userData);

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
      profile = await BuyerProfile.create({ userId: newUser._id });

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

    res.status(201).json({
      user: newUser,
      profile,
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
