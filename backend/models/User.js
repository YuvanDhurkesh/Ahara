const mongoose = require("mongoose");
const { GeoPointSchema } = require("./_shared");

const userSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      unique: true,
      index: true
    },

    role: {
      type: String,
      enum: ["buyer", "seller", "volunteer"],
      required: true,
      index: true
    },

    name: { type: String, required: true },
    phone: { type: String, required: true, index: true },
    email: { type: String },

    phoneVerified: { type: Boolean, default: false },
    emailVerified: { type: Boolean, default: false },

    // Location
    geo: GeoPointSchema,
    addressText: String,
    city: String,
    state: String,
    pincode: String,

    
    // Trust system (0-100) for buyers, sellers and volunteers
    trustScore: {
      type: Number,
      min: 0,
      max: 100
    },

    accountStatus: {
      type: String,
      enum: ["active", "warned", "locked"],
      default: "active"
    },

    profilePictureUrl: String,
    language: {
      type: String,
      enum: ["en", "hi", "ta", "te"],
      default: "en"
    },
    uiMode: {
      type: String,
      enum: ["standard", "simplified"],
      default: "standard"
    },

    // Notifications
    fcmTokens: [{ type: String }],

    isActive: { type: Boolean, default: true },

    // Soft delete
    deletedAt: {
      type: Date,
      default: null,
      index: true
    }
  },
  { timestamps: true }
);


// Geo index for proximity search
userSchema.index({ geo: "2dsphere" });


module.exports = mongoose.model("User", userSchema);
