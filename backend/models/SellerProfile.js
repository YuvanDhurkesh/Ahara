const mongoose = require("mongoose");
const { GeoPointSchema } = require("./_shared");

const sellerProfileSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true, index: true },

        orgName: { type: String, required: true },
        orgType: {
            type: String,
            enum: ["restaurant", "cafe", "cloud_kitchen", "event_company", "organization", "other"],
            required: true
        },

        businessGeo: GeoPointSchema,
        businessAddressText: String,
        businessCity: String,
        businessState: String,
        businessPincode: String,

        // FSSAI verification
        fssai: {
            number: { type: String }, // Made optional
            certificateUrl: { type: String }, // Made optional
            verified: { type: Boolean, default: false },
            verifiedAt: Date,
            verifiedBy: { type: String, enum: ["admin", "system"], default: null }
        },

        // Payout details
        payout: {
            upiId: String,
            kycStatus: { type: String, enum: ["not_started", "pending", "verified", "rejected"], default: "not_started" }
        },

        stats: {
            avgRating: { type: Number, default: 0 },
            ratingCount: { type: Number, default: 0 },
            totalListings: { type: Number, default: 0 },
            totalOrdersCompleted: { type: Number, default: 0 }
        }
    },
    { timestamps: true }
);

sellerProfileSchema.index({ businessGeo: "2dsphere" });

module.exports = mongoose.model("SellerProfile", sellerProfileSchema);
