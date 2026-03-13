const mongoose = require("mongoose");

const buyerProfileSchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true, index: true },

        favouriteSellers: [{ type: String }],
        favouriteListings: [{ type: String }],

        dietaryPreferences: [{ type: String, enum: ["vegetarian", "vegan", "non_veg", "jain"] }],

        impact: {
            foodSavedKg: { type: Number, default: 0 },
            co2SavedKg: { type: Number, default: 0 }
        },

        stats: {
            totalOrders: { type: Number, default: 0 },
            cancelledOrders: { type: Number, default: 0 }
        }
    },
    { timestamps: true }
);

module.exports = mongoose.model("BuyerProfile", buyerProfileSchema);
