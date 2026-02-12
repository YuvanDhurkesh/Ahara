const mongoose = require("mongoose");
const { GeoPointSchema } = require("./_shared");

const listingSchema = new mongoose.Schema(
    {
        sellerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        sellerProfileId: { type: mongoose.Schema.Types.ObjectId, ref: "SellerProfile", required: true },

        foodName: { type: String, required: true },
        foodType: { type: String, enum: ["vegetarian", "vegan", "non_veg", "jain"], required: true },
        category: { type: String, enum: ["cooked", "raw", "packaged", "bakery", "other"], default: "other" },

        quantityText: { type: String, required: true }, // "Serves 10", "5 kg"
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

        activeOrderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order", default: null }
    },
    { timestamps: true }
);

listingSchema.index({ pickupGeo: "2dsphere" });
listingSchema.index({ status: 1, "pickupWindow.to": 1 });

module.exports = mongoose.model("Listing", listingSchema);
