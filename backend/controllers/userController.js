const User = require("../models/User");


// ======================================================
// CREATE USER (SAFE + IDEMPOTENT)
// ======================================================

exports.createUser = async (req, res) => {

  try {

    const {
      firebaseUid,
      name,
      email,
      role,
      phone,
      location
    } = req.body.firebaseUID;


    //---------------------------------------------------
    // 🔥 HARD VALIDATION
    //---------------------------------------------------

    if (!firebaseUid) {
      return res.status(400).json({
        error: "firebaseUID is required"
      });
    }


    //---------------------------------------------------
    // ✅ CHECK IF USER ALREADY EXISTS
    //---------------------------------------------------

    const existingUser = await User.findOne({
      firebaseUid: firebaseUid
    });

    if (existingUser) {

      // SAFE RESPONSE — do NOT throw error
      return res.status(200).json({
        message: "User already exists",
        user: existingUser
      });
    }


    //---------------------------------------------------
    // ✅ CREATE NEW USER
    //---------------------------------------------------

    const newUser = await User.create({

      firebaseUid,
      name: name || "",
      email: email || "",
      role: role || "buyer",
      phone: phone || "",
      location: location || ""

    });


    //---------------------------------------------------
    // SUCCESS
    //---------------------------------------------------

    res.status(201).json({
      message: "User created successfully",
      user: newUser
    });

  }

  //-------------------------------------------------------
  // 🔥 DUPLICATE KEY GUARD (VERY IMPORTANT)
  //-------------------------------------------------------

  catch (error) {

    if (error.code === 11000) {

      // Happens when unique index hits
      const user = await User.findOne({
        firebaseUid: req.body.firebaseUID
      });

      return res.status(200).json({
        message: "User already exists",
        user
      });
    }

    console.error("Create User Error:", error);

    res.status(500).json({
      error: "Server error while creating user"
    });
  }
};
