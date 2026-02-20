const mongoose = require("mongoose");

const connectDB = async () => {
  console.log("Attempting MongoDB connection...");
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 5000, // fail fast if cannot connect
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error("❌ MongoDB Connection Failed");
    console.error("Reason:", error.message);

    // Don't crash immediately — allow debugging
    process.exit(1);
  }
};

module.exports = connectDB;