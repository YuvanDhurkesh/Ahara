const multer = require('multer');
const path = require('path');

// Configure storage
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage: storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        console.log("Filtering file:", file.originalname, "Mime:", file.mimetype);
        const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
        const extension = path.extname(file.originalname).toLowerCase();

        if (file.mimetype.startsWith('image/') || allowedExtensions.includes(extension)) {
            cb(null, true);
        } else {
            cb(new Error('Only images are allowed'));
        }
    }
});

exports.uploadImage = upload.single('image');

exports.sendUploadResponse = (req, res) => {
    console.log("--- IMAGE UPLOAD REQUEST RECEIVED ---");

    if (!req.file) {
        console.error("No file found in request. Body:", req.body);
        return res.status(400).json({ error: "No file uploaded" });
    }

    console.log("File saved to:", req.file.path);

    // Calculate the URL
    // Note: For production, this should be the full URL. 
    // For local/ngrok, we'll return a relative path that the client can combine with baseUrl
    const imageUrl = `/uploads/${req.file.filename}`;
    console.log("Generated URL:", imageUrl);

    res.status(200).json({
        message: "Image uploaded successfully",
        imageUrl: imageUrl
    });
};
