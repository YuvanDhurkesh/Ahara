const express = require("express");
const cors = require("cors");
require("dotenv").config();

const app = express();
const connectDB = require("./config/db");
const userRoutes = require("./routes/userRoutes");

if (process.env.NODE_ENV !== 'test') {
  connectDB();
}

/// ✅ ALWAYS FIRST
app.use(cors());

/// ✅ THEN JSON
app.use(express.json());

/// ✅ THEN ROUTES
app.use("/api/users", userRoutes);

app.get("/", (req, res) => {
  res.send("Backend is running 🚀");
});

const PORT = process.env.PORT || 5000;

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
