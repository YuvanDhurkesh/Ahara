const multer = require('multer');
const path = require('path');
const { v2: cloudinary } = require('cloudinary');
const { createWorker } = require('tesseract.js');
const User = require('../models/User');
const SellerProfile = require('../models/SellerProfile');

// Configure Cloudinary with env vars
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

// ──────────────────────────────────────────────
// Multer: store in memory so we can run OCR
// before deciding whether to upload to Cloudinary
// ──────────────────────────────────────────────
const memoryStorage = multer.memoryStorage();

const fssaiUpload = multer({
    storage: memoryStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (req, file, cb) => {
        const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
        const ext = path.extname(file.originalname).toLowerCase();
        if (file.mimetype.startsWith('image/') || allowedExtensions.includes(ext)) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'));
        }
    },
});

// Middleware: accept single file field named 'certificate'
exports.uploadMiddleware = fssaiUpload.single('certificate');

// ──────────────────────────────────────────────
// POST /api/users/seller/fssai/:uid
// OCR-gated FSSAI certificate verification
// ──────────────────────────────────────────────
exports.verifyFssaiCertificate = async (req, res) => {
    try {
        const { uid } = req.params;
        const { fssaiNumber } = req.body;

        // ── Step 1: Regex validation ────────────────
        if (!fssaiNumber || !/^\d{14}$/.test(fssaiNumber)) {
            return res.status(400).json({
                error: 'FSSAI number must be exactly 14 digits.',
            });
        }

        // ── Verify user exists and is a seller ──────
        const user = await User.findOne({ firebaseUid: uid });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        if (user.role !== 'seller') {
            return res.status(403).json({ error: 'Only sellers can upload FSSAI certificates' });
        }

        // ── Ensure file was uploaded ────────────────
        if (!req.file) {
            return res.status(400).json({ error: 'No certificate image uploaded' });
        }

        // ── Step 2: OCR scan ────────────────────────
        let extractedText = '';
        let worker;
        try {
            worker = await createWorker('eng');
            const { data: { text } } = await worker.recognize(req.file.buffer);
            extractedText = text.toLowerCase();
        } catch (ocrError) {
            console.error('OCR processing error:', ocrError);
            return res.status(500).json({ error: 'Failed to process the certificate image. Please try again.' });
        } finally {
            if (worker) {
                await worker.terminate();
            }
        }

        // ── Step 3: Validation logic ────────────────
        const hasNumber = extractedText.includes(fssaiNumber);
        const hasFssaiKeyword = extractedText.includes('fssai');
        const hasFoodSafety = extractedText.includes('food safety');
        const hasLicence = extractedText.includes('licence') || extractedText.includes('license');

        const isValid = hasNumber || (hasFssaiKeyword && (hasFoodSafety || hasLicence));

        // ── Step 4: Success or Fail ─────────────────
        if (!isValid) {
            return res.status(400).json({
                error: 'We could not detect a valid FSSAI certificate in this image. Please ensure the image is clear and contains your FSSAI number.',
            });
        }

        // ── Upload to Cloudinary ────────────────────
        const cloudinaryResult = await new Promise((resolve, reject) => {
            const stream = cloudinary.uploader.upload_stream(
                {
                    folder: 'ahara/fssai_certificates',
                    resource_type: 'image',
                    transformation: [{ width: 1200, crop: 'limit', quality: 'auto' }],
                },
                (error, result) => {
                    if (error) reject(error);
                    else resolve(result);
                }
            );
            stream.end(req.file.buffer);
        });

        const certificateUrl = cloudinaryResult.secure_url;

        // ── Update SellerProfile in MongoDB ─────────
        const updatedProfile = await SellerProfile.findOneAndUpdate(
            { userId: user._id },
            {
                $set: {
                    'fssai.number': fssaiNumber,
                    'fssai.certificateUrl': certificateUrl,
                    'fssai.verified': true,
                    'fssai.verifiedAt': new Date(),
                    'fssai.verifiedBy': 'system',
                },
            },
            { new: true }
        );

        if (!updatedProfile) {
            return res.status(404).json({ error: 'Seller profile not found' });
        }

        return res.status(200).json({
            message: 'FSSAI certificate verified and uploaded successfully',
            fssai: updatedProfile.fssai,
        });

    } catch (error) {
        console.error('FSSAI Verification Error:', error);
        return res.status(500).json({
            error: 'Server error during FSSAI verification',
            details: error.message,
        });
    }
};
