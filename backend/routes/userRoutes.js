const express = require("express");
const router = express.Router();
const User = require("../models/User");

const userController = require('../controllers/userController');

router.post("/create", userController.createUser);
router.get("/firebase/:uid", userController.getUserByFirebaseUid);
router.put("/:uid/volunteer-profile", userController.updateVolunteerProfile);
router.put("/:uid/seller-profile", userController.updateSellerProfile);

// Preferences routes
router.put("/:uid/preferences", userController.updatePreferences);
router.get("/:uid/preferences", userController.getPreferences);

// Favourites
router.post("/:uid/toggle-favorite-listing", userController.toggleFavoriteListing);

module.exports = router;
