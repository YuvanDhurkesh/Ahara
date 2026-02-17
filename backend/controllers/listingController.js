const Listing = require("../models/Listing");
const Order = require("../models/Order");
const SellerProfile = require("../models/SellerProfile");
const PerishabilityEngine = require("../utils/perishabilityEngine");

// Create a new listing
exports.createListing = async (req, res) => {
    try {
        console.log("--- CREATE LISTING REQUEST ---");
        console.log("Full Body:", JSON.stringify(req.body, null, 2));
        console.log("Images received:", req.body.images);

        const {
            sellerId,
            sellerProfileId,
            foodName,
            foodType,
            category,
            quantityText,
            totalQuantity,
            pricing,
            pickupWindow,
            pickupGeo,
            pickupAddressText,
            description,
            images,
            options,
            dietaryType
        } = req.body;

        // 1. Core Validation
        if (!sellerId || !sellerProfileId || !foodName || totalQuantity === undefined || !pickupWindow) {
            console.error("Validation failed: Missing required core fields");
            return res.status(400).json({
                error: "Missing required fields",
                received: { sellerId: !!sellerId, sellerProfileId: !!sellerProfileId, foodName: !!foodName, totalQuantity: totalQuantity !== undefined, pickupWindow: !!pickupWindow }
            });
        }

        // 2. Normalize Enums
        const normalizedFoodType = foodType ? foodType.toLowerCase() : "other";
        const normalizedCategory = category ? category.toLowerCase() : "other";

        // 3. Ensure Numeric Quantity
        const numericQuantity = Number(totalQuantity);
        if (isNaN(numericQuantity)) {
            return res.status(400).json({ error: "totalQuantity must be a number" });
        }

        // 4. Safety Validation
        const safetyValidation = PerishabilityEngine.validateSafety(
            normalizedFoodType,
            new Date(pickupWindow.from),
            new Date(pickupWindow.to)
        );

        if (!safetyValidation.isValid) {
            console.warn(`Safety Rejection: ${safetyValidation.details}`);
            return res.status(400).json({
                error: "Safety validation failed",
                translationKey: safetyValidation.translationKey,
                details: safetyValidation.details,
                safetyThreshold: safetyValidation.safetyThreshold
            });
        }

        // 5. Handle Geo JSON safely
        let geoData = null;
        if (pickupGeo && pickupGeo.coordinates && Array.isArray(pickupGeo.coordinates) && pickupGeo.coordinates.length === 2) {
            geoData = {
                type: "Point",
                coordinates: [Number(pickupGeo.coordinates[0]), Number(pickupGeo.coordinates[1])]
            };
        }

        // 5. Build the object
        const listingData = {
            sellerId,
            sellerProfileId,
            foodName,
            dietaryType: dietaryType || "not_specified",
            foodType: normalizedFoodType,
            category: normalizedCategory,
            quantityText: quantityText || `${numericQuantity}`,
            totalQuantity: numericQuantity,
            remainingQuantity: numericQuantity,
            pricing: pricing ? {
                originalPrice: pricing.originalPrice,
                discountedPrice: pricing.discountedPrice !== undefined ? pricing.discountedPrice : 0,
                isFree: pricing.isFree || false
            } : { discountedPrice: 0, isFree: true },
            pickupWindow,
            pickupAddressText: pickupAddressText || "",
            description: description || "",
            images: images || [],
            options: options || { selfPickupAvailable: true, deliveryAvailable: true },
            status: "active",
            isSafetyValidated: true,
            safetyStatus: "validated",
            safetyThreshold: safetyValidation.safetyThreshold
        };

        if (geoData) {
            listingData.pickupGeo = geoData;
        }

        console.log("Attempting to save listing to MongoDB...");
        const newListing = await Listing.create(listingData);
        console.log("!!! SAVE SUCCESS !!! ID:", newListing._id);

        res.status(201).json({
            message: "Listing created successfully",
            listing: newListing
        });
    } catch (error) {
        console.error("!!! CREATE LISTING CRASH !!!");
        console.error("Error Name:", error.name);
        console.error("Error Message:", error.message);

        if (error.name === 'ValidationError') {
            return res.status(400).json({
                error: "Validation failed",
                details: error.message,
                fields: error.errors
            });
        }

        res.status(500).json({
            error: "Server error during listing creation",
            details: error.message
        });
    }
};

exports.updateListing = async (req, res) => {
    try {
        const { id } = req.params;
        console.log(`--- UPDATE LISTING REQUEST [ID: ${id}] ---`);
        console.log("Full Body:", JSON.stringify(req.body, null, 2));
        console.log("Images in update:", req.body.images);

        const updatedListing = await Listing.findByIdAndUpdate(
            id,
            { $set: req.body },
            { new: true, runValidators: true }
        );

        if (!updatedListing) {
            return res.status(404).json({ error: "Listing not found" });
        }

        console.log("!!! UPDATE SUCCESS !!! ID:", updatedListing._id);
        res.status(200).json({
            message: "Listing updated successfully",
            listing: updatedListing
        });
    } catch (error) {
        console.error("!!! UPDATE LISTING CRASH !!!", error);
        res.status(500).json({
            error: "Server error during listing update",
            details: error.message
        });
    }
};

// Get active listings
exports.getActiveListings = async (req, res) => {
    try {
        const { sellerId } = req.query;
        const now = new Date();
        const query = {
            status: "active",
            remainingQuantity: { $gt: 0 },
            "pickupWindow.to": { $gt: now }
        };

        if (sellerId) query.sellerId = sellerId;

        const listings = await Listing.find(query).sort({ "pickupWindow.to": 1 });

        res.status(200).json(listings);
    } catch (error) {
        res.status(500).json({ error: "Server error", details: error.message });
    }
};

// Get expired listings
exports.getExpiredListings = async (req, res) => {
    try {
        const { sellerId } = req.query;
        const now = new Date();
        const query = {
            status: "active",
            remainingQuantity: { $gt: 0 },
            "pickupWindow.to": { $lte: now }
        };

        if (sellerId) query.sellerId = sellerId;

        const listings = await Listing.find(query);

        res.status(200).json(listings);
    } catch (error) {
        res.status(500).json({ error: "Server error", details: error.message });
    }
};

// Get completed listings
exports.getCompletedListings = async (req, res) => {
    try {
        const { sellerId } = req.query;
        const query = {
            $or: [
                { status: "completed" },
                { remainingQuantity: 0 }
            ]
        };

        if (sellerId) query.sellerId = sellerId;

        const listings = await Listing.find(query);

        res.status(200).json(listings);
    } catch (error) {
        res.status(500).json({ error: "Server error", details: error.message });
    }
};

// Get Seller Dashboard Stats
exports.getSellerStats = async (req, res) => {
    try {
        const { sellerId } = req.query;
        if (!sellerId) {
            return res.status(400).json({ error: "sellerId is required" });
        }

        const now = new Date();
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(now.getDate() - 30);

        // 1. Active Listings Count
        const activeListingsCount = await Listing.countDocuments({
            sellerId,
            status: "active",
            remainingQuantity: { $gt: 0 },
            "pickupWindow.to": { $gt: now }
        });

        // 2. Pending Orders Count
        const pendingOrdersCount = await Order.countDocuments({
            sellerId,
            status: { $in: ["placed", "awaiting_volunteer", "volunteer_assigned", "volunteer_accepted", "picked_up", "in_transit"] }
        });

        // 3. Avg Rating from SellerProfile
        const sellerProfile = await SellerProfile.findOne({ userId: sellerId });
        const avgRating = sellerProfile ? sellerProfile.stats.avgRating : 0;

        // 4. Monthly Earnings (last 30 days)
        const mongoose = require('mongoose');
        const monthlyEarningsResult = await Order.aggregate([
            {
                $match: {
                    sellerId: new mongoose.Types.ObjectId(sellerId),
                    status: "delivered",
                    updatedAt: { $gte: thirtyDaysAgo }
                }
            },
            {
                $group: {
                    _id: null,
                    totalEarnings: { $sum: "$pricing.total" }
                }
            }
        ]);

        const monthlyEarnings = monthlyEarningsResult.length > 0 ? monthlyEarningsResult[0].totalEarnings : 0;

        res.status(200).json({
            activeListings: activeListingsCount,
            pendingOrders: pendingOrdersCount,
            avgRating: avgRating,
            monthlyEarnings: monthlyEarnings
        });

    } catch (error) {
        console.error("Error fetching seller stats:", error);
        res.status(500).json({ error: "Server error fetching statistics", details: error.message });
    }
};
