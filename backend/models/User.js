const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({

  firebaseUid: {
    type: String,
    required: true,
    unique: true,
  },

  name: String,
  email: String,
  role: String,
  phone: String,
  location: String,

  // Gamification Fields
  points: { type: Number, default: 0 },
  level: { type: Number, default: 1 },
  badges: [{ type: String }], // e.g., ["First Donation", "Super Volunteer"]

  // Trust Score System
  trustScore: { type: Number, default: 50, min: 0, max: 100 },

}, { timestamps: true });

module.exports = mongoose.model("User", userSchema);
