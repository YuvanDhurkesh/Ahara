const Listing = require("../models/Listing");
const Order = require("../models/Order");
const SellerProfile = require("../models/SellerProfile");
const PerishabilityEngine = require("../utils/perishabilityEngine");
const { generateDefaultImageUrl } = require("../utils/imageGenerator");
const { translateText } = require("../services/translationService");

// Helper: Ensure listing has an image. If not, generate one and save it.
async function ensureListingHasImage(listing) {
    const listingObj = listing.toObject ? listing.toObject() : listing;

    const isOldGenerator = listingObj.images &&
        listingObj.images.length > 0 &&
        (listingObj.images[0].includes('dicebear.com') ||
            listingObj.images[0].includes('placeholder.com'));

    if (!listingObj.images || listingObj.images.length === 0 || isOldGenerator) {
        const defaultImageUrl = generateDefaultImageUrl(listingObj.foodName, listingObj.category);

        // Update in database to permanently fix old entries or set new one
        if (listing._id) {
            await Listing.findByIdAndUpdate(
                listing._id,
                { images: [defaultImageUrl] },
                { new: false }
            );
        }

        // Add to object for response
        listingObj.images = [defaultImageUrl];
    }

    return listingObj;
}

// Create a new listing
exports.createListing = async (req, res) => {
    try {
        console.log("--- CREATE LISTING REQUEST ---");
        console.log("Full Body:", JSON.stringify(req.body, null, 2));
        console.log("Images received:", req.body.images);
        console.log("pickupGeo in req.body:", req.body.pickupGeo);

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

        // 6. Handle images - generate default if none provided
        let imageList = images || [];
        if (!imageList || imageList.length === 0) {
            const defaultImageUrl = generateDefaultImageUrl(foodName, normalizedCategory);
            imageList = [defaultImageUrl];
            console.log(`Generated default image for ${foodName}: ${defaultImageUrl}`);
        }

        // 7. Translate Dynamic Content
        console.log(`Translating content for listing: ${foodName}`);
        const [foodNameTranslations, descriptionTranslations] = await Promise.all([
            translateText(foodName),
            description ? translateText(description) : Promise.resolve({ hi: "", ta: "", te: "" })
        ]);

        const translations = {
            hi: { foodName: foodNameTranslations.hi, description: descriptionTranslations.hi },
            ta: { foodName: foodNameTranslations.ta, description: descriptionTranslations.ta },
            te: { foodName: foodNameTranslations.te, description: descriptionTranslations.te }
        };

        // 8. Build the object
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
            images: imageList,
            translations,
            options: options || { selfPickupAvailable: true, deliveryAvailable: true },
            status: "active",
            isSafetyValidated: true,
            safetyStatus: "validated",
            safetyThreshold: safetyValidation.safetyThreshold
        };

        if (geoData) {
            listingData.pickupGeo = geoData;
        }

        console.log("Attempting to save listing to MongoDB with pickupGeo:", JSON.stringify(listingData.pickupGeo, null, 2));
        const newListing = await Listing.create(listingData);
        console.log("!!! SAVE SUCCESS !!! ID:", newListing._id, "has pickupGeo:", !!newListing.pickupGeo);

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

        let updateData = { ...req.body };

        // Handle Translations if foodName or description changed
        if (updateData.foodName || updateData.description) {
            const currentListing = await Listing.findById(id);
            if (!currentListing) {
                return res.status(404).json({ error: "Listing not found" });
            }

            const foodNameToTranslate = updateData.foodName || currentListing.foodName;
            const descToTranslate = updateData.description !== undefined ? updateData.description : currentListing.description;

            console.log(`Re-translating modified content for updated listing [ID: ${id}]`);
            const [foodNameTranslations, descriptionTranslations] = await Promise.all([
                translateText(foodNameToTranslate),
                descToTranslate ? translateText(descToTranslate) : Promise.resolve({ hi: "", ta: "", te: "" })
            ]);

            updateData.translations = {
                hi: { foodName: foodNameTranslations.hi, description: descriptionTranslations.hi },
                ta: { foodName: foodNameTranslations.ta, description: descriptionTranslations.ta },
                te: { foodName: foodNameTranslations.te, description: descriptionTranslations.te }
            };
        }

        const updatedListing = await Listing.findByIdAndUpdate(
            id,
            { $set: updateData },
            { new: true, runValidators: true }
        );

        if (!updatedListing) {
            return res.status(404).json({ error: "Listing not found" });
        }

        console.log("!!! UPDATE SUCCESS !!! ID:", updatedListing._id);

        // Ensure listing has image
        const listingWithImage = await ensureListingHasImage(updatedListing);

        res.status(200).json({
            message: "Listing updated successfully",
            listing: listingWithImage
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

        const listings = await Listing.find(query)
            .populate("sellerProfileId")
            .sort({ "pickupWindow.to": 1 });

        // Ensure all listings have images
        const listingsWithImages = await Promise.all(
            listings.map(listing => ensureListingHasImage(listing))
        );

        res.status(200).json(listingsWithImages);
    } catch (error) {
        res.status(500).json({ error: "Server error", details: error.message });
    }
};

// Get expired listings - based on time, not status
exports.getExpiredListings = async (req, res) => {
    try {
        const { sellerId } = req.query;
        const now = new Date();
        const query = {
            "pickupWindow.to": { $lte: now }
        };

        if (sellerId) query.sellerId = sellerId;

        const listings = await Listing.find(query).sort({ "pickupWindow.to": -1 });

        // Ensure all listings have images
        const listingsWithImages = await Promise.all(
            listings.map(listing => ensureListingHasImage(listing))
        );

        res.status(200).json(listingsWithImages);
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

        // Ensure all listings have images
        const listingsWithImages = await Promise.all(
            listings.map(listing => ensureListingHasImage(listing))
        );

        res.status(200).json(listingsWithImages);
    } catch (error) {
        res.status(500).json({ error: "Server error", details: error.message });
    }
};

// Relist an expired listing with new pickup window
exports.relistListing = async (req, res) => {
    try {
        const { id } = req.params;
        const { pickupWindow } = req.body;

        if (!pickupWindow || !pickupWindow.from || !pickupWindow.to) {
            return res.status(400).json({ error: "pickupWindow with from and to is required" });
        }

        // Get the original listing to restore totalQuantity
        const originalListing = await Listing.findById(id);
        if (!originalListing) {
            return res.status(404).json({ error: "Listing not found" });
        }

        const updatedListing = await Listing.findByIdAndUpdate(
            id,
            {
                pickupWindow,
                status: "active",
                remainingQuantity: originalListing.totalQuantity
            },
            { new: true, runValidators: true }
        );

        // Ensure listing has image
        const listingWithImage = await ensureListingHasImage(updatedListing);

        res.status(200).json({
            message: "Listing relisted successfully",
            listing: listingWithImage
        });
    } catch (error) {
        console.error("Error relisting:", error);
        res.status(500).json({ error: "Server error", details: error.message });
    }
};

// Delete a listing
exports.deleteListing = async (req, res) => {
    try {
        const { id } = req.params;

        // Check if there are active orders for this listing
        const activeOrders = await Order.countDocuments({
            listingId: id,
            status: { $in: ["placed", "awaiting_volunteer", "volunteer_assigned", "volunteer_accepted", "picked_up", "in_transit"] }
        });

        if (activeOrders > 0) {
            return res.status(400).json({
                error: "Cannot delete listing with active orders. Complete or cancel orders first."
            });
        }

        const deletedListing = await Listing.findByIdAndDelete(id);

        if (!deletedListing) {
            return res.status(404).json({ error: "Listing not found" });
        }

        res.status(200).json({ message: "Listing deleted successfully" });
    } catch (error) {
        console.error("Delete Listing Error:", error);
        res.status(500).json({ error: "Server error during deletion", details: error.message });
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

// Get favorite listings for a user
exports.getFavoriteListings = async (req, res) => {
    try {
        const { uid } = req.params;
        const User = require("../models/User");
        const BuyerProfile = require("../models/BuyerProfile");

        const user = await User.findOne({ firebaseUid: uid });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        const profile = await BuyerProfile.findOne({ userId: user._id });
        if (!profile || !profile.favouriteListings || profile.favouriteListings.length === 0) {
            return res.status(200).json([]);
        }

        const listings = await Listing.find({
            _id: { $in: profile.favouriteListings },
            status: "active" // Only show active favorites
        }).populate("sellerProfileId");

        // Ensure all listings have images
        const listingsWithImages = await Promise.all(
            listings.map(listing => ensureListingHasImage(listing))
        );

        res.status(200).json(listingsWithImages);
    } catch (error) {
        console.error("Error fetching favorite listings:", error);
        res.status(500).json({ error: "Server error fetching favorite listings", details: error.message });
    }
};
