const User = require("../models/User");

exports.createUser = async (req, res) => {
  try {
    console.log("Incoming body:", req.body); // debug

    const {
      firebaseUid,
      email,
      name,
      role,
      phone,
      location
    } = req.body;

    // Validate required fields
    if (!firebaseUid || !email) {
      return res.status(400).json({
        error: "firebaseUid and email are required"
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ firebaseUid });

    if (existingUser) {
      return res.status(200).json(existingUser);
    }

    // Create new user
    const newUser = await User.create({
      firebaseUid,
      email,
      name,
      role,
      phone,
      location
    });

    res.status(201).json(newUser);

  } catch (error) {
    console.error("Create User Error:", error);
    res.status(500).json({
      error: "Server error while creating user"
    });
  }
};
