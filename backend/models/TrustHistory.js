const mongoose = require("mongoose");

const trustHistorySchema = new mongoose.Schema(
    {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
        delta: { type: Number, required: true },
        reason: { type: String, required: true },
        orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order" },
        createdBy: { type: String, enum: ["system", "admin"], default: "system" }
    },
    { timestamps: true }
);

module.exports = mongoose.model("TrustHistory", trustHistorySchema);
