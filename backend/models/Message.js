const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema(
    {
        orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order", required: true, index: true },
        senderId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        senderRole: { type: String, enum: ["buyer", "seller", "volunteer"], required: true },
        text: { type: String, required: true },
    },
    { timestamps: true }
);

// Index to quickly fetch messages for a specific order chronologically
messageSchema.index({ orderId: 1, createdAt: 1 });

module.exports = mongoose.model("Message", messageSchema);
