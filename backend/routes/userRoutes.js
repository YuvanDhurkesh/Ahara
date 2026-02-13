const express = require("express");
const router = express.Router();
const User = require("../models/User");

const userController = require('../controllers/userController');
const gamificationController = require('../controllers/gamificationController');

router.post("/create", userController.createUser);


// Gamification Routes
router.post("/points/add", gamificationController.addPoints);
router.get("/profile/:userId", gamificationController.getGamificationProfile);
router.post("/trust/update", gamificationController.updateTrustScore);

module.exports = router;
