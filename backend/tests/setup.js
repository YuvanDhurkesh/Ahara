const mongoose = require('mongoose');
const dotenv = require('dotenv');

dotenv.config();

// Use a separate test database via environment variable
const TEST_MONGODB_URI = process.env.TEST_MONGODB_URI || 'mongodb://localhost:27017/ahara_test';

exports.connect = async () => {
    try {
        // Connect to test database
        await mongoose.connect(TEST_MONGODB_URI, {
            serverSelectionTimeoutMS: 30000,
            socketTimeoutMS: 30000,
            connectTimeoutMS: 30000,
        });

        // Wait for connection to be ready
        await new Promise(resolve => {
            if (mongoose.connection.readyState === 1) {
                resolve();
            } else {
                mongoose.connection.once('connected', resolve);
            }
        });

        console.log('✅ Connected to test database:', TEST_MONGODB_URI);
    } catch (error) {
        console.error('❌ Failed to connect test database:', error.message);
        throw error;
    }
};

exports.disconnect = async () => {
    try {
        if (mongoose.connection.readyState !== 0) {
            await mongoose.disconnect();
        }
        console.log('✅ Test database disconnected');
    } catch (error) {
        console.error('❌ Failed to disconnect test database:', error);
        throw error;
    }
};
