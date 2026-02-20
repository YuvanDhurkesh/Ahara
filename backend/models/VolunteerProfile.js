const mongoose = require("mongoose");

const volunteerProfileSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true,
            index: true
        },

        transportMode: {
            type: String,
            enum: ["walk", "cycle", "bike", "car"],
            required: true
        },

        availability: {
            isAvailable: { type: Boolean, default: false },
            maxConcurrentOrders: { type: Number, default: 1 },
            activeOrders: { type: Number, default: 0 }
        },

        verification: {
            level: { type: Number, default: 0 }, // 0..3

            emailVerified: { type: Boolean, default: false },
            phoneVerified: { type: Boolean, default: false },

            driversLicense: {
                submitted: { type: Boolean, default: false },
                documentUrl: String,
                verified: { type: Boolean, default: false }
            },

            idProof: {
                submitted: { type: Boolean, default: false },
                documentUrl: String,
                verified: { type: Boolean, default: false }
            }
        },

        // Age verification (privacy-friendly)
        ageVerification: {
            ageVerified: { type: Boolean, default: false },
            verifiedAt: Date,
            method: {
                type: String,
                enum: ["self_declaration", "id_proof", "drivers_license"],
                default: "self_declaration"
            }
        },

        badge: {
            tickVerified: { type: Boolean, default: false },
            awardedAt: Date
        },

        stats: {
            avgRating: { type: Number, default: 0 },
            ratingCount: { type: Number, default: 0 },

            totalDeliveriesCompleted: { type: Number, default: 0 },
            totalDeliveriesFailed: { type: Number, default: 0 },

            lateDeliveries: { type: Number, default: 0 },
            noShows: { type: Number, default: 0 }
        }
    },
    { timestamps: true }
);

module.exports = mongoose.model("VolunteerProfile", volunteerProfileSchema);
