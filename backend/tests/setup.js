const mongoose = require('mongoose');
const { MongoMemoryReplSet } = require('mongodb-memory-server');

let replSet;

exports.connect = async () => {
    try {
        if (mongoose.connection.readyState !== 0) {
            return;
        }

        if (!replSet) {
            replSet = await MongoMemoryReplSet.create({
                binary: {
                    version: '7.0.5', // Specify version to force a fresh download/bypass corrupted cache
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
            if (!existingCollections.includes(col)) {
                await mongoose.connection.db.createCollection(col);
                // "Warm up" the collection with a dummy operation to ensure it's in the catalog
                const tempDoc = await mongoose.connection.db.collection(col).insertOne({ _temp: true });
                await mongoose.connection.db.collection(col).deleteOne({ _id: tempDoc.insertedId });
            }
        }
        console.log('✅ Pre-created and warmed up collections');

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