const mongoose = require('mongoose');
const { MongoMemoryReplSet } = require('mongodb-memory-server');

let replSet;

exports.connect = async () => {
    try {
        // Start MongoMemoryReplSet for transaction support
        replSet = await MongoMemoryReplSet.create({
            replSet: { count: 1, storageEngine: 'wiredTiger' }
        });
        const uri = replSet.getUri();

        // Connect to the in-memory replica set
        await mongoose.connect(uri);
        console.log('✅ Connected to in-memory test replica set');
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
        }
        console.log('✅ Test replica set disconnected');
    } catch (error) {
        console.error('❌ Failed to disconnect test replica set:', error);
        throw error;
    }
};