require('dotenv').config();
const mongoose = require('mongoose');
const Listing = require('./models/Listing');
const { translateText } = require('./services/translationService');

async function runTest() {
    try {
        console.log('Connecting to DB...');
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected.');

        console.log('Testing translation service directly...');
        const textToTranslate = "Spicy Chicken Biryani with raita";
        console.log(`Original: ${textToTranslate}`);
        const translations = await translateText(textToTranslate);
        console.log('Translations:');
        console.log(translations);

    } catch (error) {
        console.error('Test failed:', error);
    } finally {
        await mongoose.disconnect();
        console.log('Disconnected.');
    }
}

runTest();
