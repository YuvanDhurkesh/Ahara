const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const app = express();
const connectDB = require("./config/db");
const userRoutes = require("./routes/userRoutes");
const listingRoutes = require("./routes/listingRoutes");
const orderRoutes = require("./routes/orderRoutes");
const uploadRoutes = require("./routes/uploadRoutes");
const paymentRoutes = require("./routes/paymentRoutes");
const otpRoutes = require("./routes/otpRoutes");

if (process.env.NODE_ENV !== 'test') {
  connectDB();
}

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Middleware - CORS with explicit configuration
app.use(cors({
  origin: function (origin, callback) {
    // Allow all origins for development (ngrok, localhost, etc)
    callback(null, true);
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'ngrok-skip-browser-warning'],
  credentials: false,
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

/// ✅ THEN JSON
app.use(express.json());

/// ✅ THEN ROUTES
app.use("/api/users", userRoutes);
app.use("/api/listings", listingRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/upload", uploadRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/otp", otpRoutes);

// Serve static uploads with ngrok bypass header (best effort)
app.use("/api/uploads", (req, res, next) => {
  res.set("ngrok-skip-browser-warning", "true");
  next();
}, express.static(path.join(__dirname, "uploads")));

// Global Error Handler
app.use((err, req, res, next) => {
  console.error("!!! SERVER ERROR !!!", err);
  res.status(500).json({ error: "Internal Server Error", details: err.message });
});

app.get("/", (req, res) => {
  res.send("Backend is running 🚀");
});

const PORT = process.env.PORT || 5000;

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
  });
}

module.exports = app;
