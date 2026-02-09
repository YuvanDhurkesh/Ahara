// Entry point for Ahara backend
// Express server for handling API requests
//
// SECURITY: No secrets or Firebase Admin logic in frontend.
//           No database access from frontend.
//           Service account and DB URI loaded from environment only.
//
// ARCHITECTURE: Firebase Auth is used for client authentication (Flutter).
//               Backend verifies ID tokens and manages user profiles in MongoDB.
//               Passwords are NEVER stored in MongoDB.

require('dotenv').config();
const express = require('express');
const app = express();

// Connect to MongoDB (exits on failure)
require('./db');

// Middleware to parse JSON bodies
app.use(express.json());

// Health check route
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Auth routes (handles /api/auth/login)
app.use('/api/auth', require('./routes/auth'));

// Start server only if not in test mode
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Ahara backend listening on port ${PORT}`);
  });
}

module.exports = app;
