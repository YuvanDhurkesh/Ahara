const express = require("express");
const router = express.Router();
const User = require("../models/User");

const userController = require('../controllers/userController');

router.post("/create", userController.createUser);

module.exports = router;
