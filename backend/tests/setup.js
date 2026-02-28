const mongoose = require('mongoose');
const { MongoMemoryReplSet } = require('mongodb-memory-server');

// Mock Cloudinary for tests
jest.mock('cloudinary', () => ({
    v2: {
        config: jest.fn(),
        uploader: {
            upload: jest.fn(),
        },
    },
}));

jest.mock('multer-storage-cloudinary', () => {
    return {
        CloudinaryStorage: jest.fn().mockImplementation(() => ({
            _handleFile: (req, file, cb) => {
                cb(null, {
                    path: 'https://res.cloudinary.com/mock-cloud/image/upload/v1/mock-path/test.png',
                    size: 1024
                });
            },
            _removeFile: (req, file, cb) => {
                cb(null);
            },
        })),
    };
});

let replSet;

exports.connect = async () => {
    try {
        if (mongoose.connection.readyState !== 0) {
            return;
        }

        if (!replSet) {
            replSet = await MongoMemoryReplSet.create({
                binary: {
                    version: '6.0.4'
                },
                replSet: {
                    count: 1,
                    storageEngine: 'wiredTiger'
                }
            });
        }

        const uri = replSet.getUri();
        await mongoose.connect(uri);
        console.log('✅ Connected to in-memory test replica set');

        // Pre-create collections to avoid catalog changes during transactions in individual tests
        const collections = ['users', 'sellerprofiles', 'listings', 'orders', 'notifications', 'otps', 'buyerprofiles', 'volunteerprofiles', 'reviews'];
        const existingCollections = (await mongoose.connection.db.listCollections().toArray()).map(c => c.name);

        for (const col of collections) {
            try {
                await mongoose.connection.db.createCollection(col);
                // "Warm up" the collection with a dummy operation to ensure it's in the catalog
                const tempDoc = await mongoose.connection.db.collection(col).insertOne({ _temp: true });
                await mongoose.connection.db.collection(col).deleteOne({ _id: tempDoc.insertedId });
            } catch (e) {
                // Ignore "Collection already exists" error (code 48)
                if (e.code !== 48) throw e;
            }
        }
        console.log('✅ Collections verified/created');

    } catch (error) {
        console.error('❌ Failed to connect to in-memory test replica set:', error);
        throw error;
    }
};

exports.disconnect = async () => {
    try {
        await mongoose.disconnect();
        if (replSet) {
            await replSet.stop();
            replSet = null;
        }
        console.log('✅ Mongoose disconnected and ReplSet stopped');
    } catch (error) {
        console.error('❌ Failed to disconnect test replica set:', error);
        throw error;
    }
};

exports.stopReplSet = async () => {
    if (replSet) {
        await replSet.stop();
        replSet = null;
    }
};