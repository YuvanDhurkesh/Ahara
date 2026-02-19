const mongoose = require('mongoose');
require('dotenv').config();
const Listing = require('./models/Listing');
const { generateDefaultImageUrl } = require('./utils/imageGenerator');

async function migrate() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("Connected to MongoDB");

        const listings = await Listing.find({
            $or: [
                { images: { $size: 0 } },
                { images: { $exists: false } },
                { "images.0": { $regex: /dicebear|placeholder|loremflickr/ } }
            ]
        });

        console.log(`Found ${listings.length} listings to fix`);

        for (const listing of listings) {
            const newUrl = generateDefaultImageUrl(listing.foodName, listing.category);
            listing.images = [newUrl];
            await listing.save();
            console.log(`Updated listing: ${listing.foodName} (${listing._id}) -> ${newUrl}`);
        }

        console.log("Migration complete ✅");
        process.exit(0);
    } catch (error) {
        console.error("Migration failed:", error);
        process.exit(1);
    }
}

migrate();
