
// Mongoose User model for Ahara
//
// Why? MongoDB stores user profile, roles, trust score, verification level.
//      Passwords are NEVER stored here (handled by Firebase Auth only).
//      This enables flexible role/trust management, and keeps secrets out of DB.

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  email: { type: String, required: true },
  roles: { type: [String], default: ['VOLUNTEER'] },
  trustScore: { type: Number, default: 0 },
  verificationLevel: { type: String, default: 'BASIC' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);
