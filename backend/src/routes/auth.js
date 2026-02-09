// Auth routes for Ahara backend
// POST /api/auth/login: verifies Firebase token, persists user, returns profile

const express = require('express');
const router = express.Router();
const User = require('../models/User');
const firebaseAuth = require('../middleware/firebaseAuth');

// POST /api/auth/login
// Protected by Firebase auth middleware
router.post('/login', firebaseAuth, async (req, res) => {
  const { uid, email } = req.user;
  try {
    let user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      // Create new user profile if not exists
      user = await User.create({ firebaseUid: uid, email });
    }
    // Return user profile (never send sensitive info)
    res.json({
      firebaseUid: user.firebaseUid,
      email: user.email,
      roles: user.roles,
      trustScore: user.trustScore,
      verificationLevel: user.verificationLevel,
      createdAt: user.createdAt,
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error', details: err.message });
  }
});

module.exports = router;
