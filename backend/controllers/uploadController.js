const multer = require('multer');
const path = require('path');
const { v2: cloudinary } = require('cloudinary');
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Use Cloudinary storage — images go straight to the CDN
const storage = new CloudinaryStorage({
    cloudinary,
    params: {
        folder: 'ahara/listings',        // Organised folder in your Cloudinary account
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'avif'],
        transformation: [{ width: 800, crop: 'limit', quality: 'auto' }], // Auto-optimise
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (req, file, cb) => {
        console.log('Filtering file:', file.originalname, 'Mime:', file.mimetype);
        const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.avif'];
        const ext = path.extname(file.originalname).toLowerCase();
        if (file.mimetype.startsWith('image/') || allowedExtensions.includes(ext)) {
            cb(null, true);
        } else {
            cb(new Error('Only images are allowed'));
        }
    },
});

exports.uploadImage = upload.single('image');

exports.sendUploadResponse = (req, res) => {
    console.log('--- IMAGE UPLOAD REQUEST RECEIVED ---');

    if (!req.file) {
        console.error('No file found in request. Body:', req.body);
        return res.status(400).json({ error: 'No file uploaded' });
    }

    // Cloudinary gives us a permanent public URL in req.file.path
    const imageUrl = req.file.path;
    console.log('Cloudinary URL:', imageUrl);

    res.status(200).json({
        message: 'Image uploaded successfully',
        imageUrl,
    });
};
