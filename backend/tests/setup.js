const { MongoMemoryServer } = require('mongodb-memory-server');
const dotenv = require('dotenv');
const mongoose = require('mongoose');

dotenv.config();



exports.connect = async () => {
    mongoServer = await MongoMemoryServer.create({
        replSet: {
            name: 'rs0',
            count: 1,
            storageEngine: 'wiredTiger',
        }
    });
    const uri = mongoServer.getUri();
    console.log("MongoMemoryServer URI:", uri);
    await mongoose.connect(uri);
};

exports.disconnect = async () => {
    if (mongoose.connection.readyState !== 0) {
        await mongoose.disconnect();
    }
    if (mongoServer) {
        await mongoServer.stop();
    }
};
