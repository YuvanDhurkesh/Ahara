const express = require("express");
const router = express.Router();
const uploadController = require("../controllers/uploadController");

router.post("/", uploadController.uploadImage, uploadController.sendUploadResponse);

// Error handling middleware for multer
router.use((err, req, res, next) => {
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(413).json({ error: "File size exceeds 5MB limit" });
    }
    if (err.message === 'Only images are allowed') {
        return res.status(400).json({ error: "Only image files are allowed" });
    }
    console.error("Upload error:", err);
    res.status(500).json({ error: err.message || "Upload failed" });
});

module.exports = router;
