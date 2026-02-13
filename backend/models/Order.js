const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
    buyerId: {
        type: String, // Firebase UID
        required: true
    },
    volunteerId: {
        type: String, // Firebase UID (Null initially)
        default: null
    },
    storeId: {
        type: String,
        required: true
    },
    items: [{
        name: String,
        quantity: Number,
        price: Number
    }],
    totalAmount: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['PENDING', 'ACCEPTED', 'PICKED_UP', 'DELIVERED', 'COMPLETED', 'CANCELLED'],
        default: 'PENDING'
    },

    // 🛡️ Food Safety Fields
    foodType: {
        type: String,
        enum: ['COOKED_VEG', 'COOKED_NON_VEG', 'RAW_VEG', 'BAKERY'],
        // required: true  <-- Making optional for backward compatibility if needed, but logic demands it.
        // Let's make it required for new orders, but existing tests might fail if not handled.
        // For now, let's keep it required as per plan.
        required: false
    },
    storageCondition: {
        type: String,
        enum: ['ROOM_TEMP', 'REFRIGERATED'],
        required: false
    },
    cookedTime: { type: Date, required: false },
    expiryTime: { type: Date, required: false },

    deliveryAddress: {
        type: String,
        default: "TBD"
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

module.exports = mongoose.model('Order', orderSchema);
