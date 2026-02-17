const express = require("express");
const router = express.Router();
const listingController = require("../controllers/listingController");

router.post("/create", listingController.createListing);
router.put("/update/:id", listingController.updateListing);
router.get("/active", listingController.getActiveListings);
router.get("/expired", listingController.getExpiredListings);
router.get("/completed", listingController.getCompletedListings);
router.get("/seller-stats", listingController.getSellerStats);
router.put("/relist/:id", listingController.relistListing);

module.exports = router;
