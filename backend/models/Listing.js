const mongoose = require("mongoose");
const { GeoPointSchema } = require("./_shared");

const listingSchema = new mongoose.Schema(
    {
        sellerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        sellerProfileId: { type: mongoose.Schema.Types.ObjectId, ref: "SellerProfile", required: true },

        foodName: { type: String, required: true },
        // Dietary restriction (Veg, Non-Veg, etc.)
        dietaryType: { type: String, enum: ["vegetarian", "vegan", "non_veg", "jain", "not_specified"], default: "not_specified" },
        // Nature of food (Meal, Produce, etc.) - Matches frontend FoodType enum
        foodType: { type: String, required: true },
        // Broad category - Matches frontend Category grouping
        category: { type: String, default: "other" },

        quantityText: { type: String, required: true }, // "Serves 10", "5 kg"
        totalQuantity: { type: Number, required: true },
        remainingQuantity: { type: Number, required: true },
        description: String,
        images: [String],

        pricing: {
            originalPrice: Number,
            discountedPrice: { type: Number, required: true },
            isFree: { type: Boolean, default: false }
        },

        pickupWindow: {
            from: { type: Date, required: true },
            to: { type: Date, required: true }
        },

        pickupGeo: GeoPointSchema,
        pickupAddressText: String,

        status: { type: String, enum: ["active", "expired", "cancelled", "completed"], default: "active", index: true },

        options: {
            selfPickupAvailable: { type: Boolean, default: true },
            deliveryAvailable: { type: Boolean, default: true }
        },
        // Safety & Lifecycle
        isSafetyValidated: { type: Boolean, default: false },
        safetyStatus: { type: String, enum: ["validated", "rejected", "pending"], default: "pending" },
        safetyRejectionReason: String,
        safetyThreshold: Date
    },
    { timestamps: true }
);

listingSchema.pre("validate", function () {
    if (this.isNew && this.totalQuantity !== undefined && this.remainingQuantity === undefined) {
        this.remainingQuantity = this.totalQuantity;
    }
});

listingSchema.index({ pickupGeo: "2dsphere" });
listingSchema.index({ status: 1, "pickupWindow.to": 1 });

module.exports = mongoose.model("Listing", listingSchema);
