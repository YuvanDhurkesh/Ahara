# Ahara Backend

This is the backend for the Ahara app. It provides authentication and user profile management using Node.js, Express, MongoDB, and Firebase Admin SDK.

## Key Points
- **Authentication:** Uses Firebase Authentication (client-side in Flutter) and verifies ID tokens in backend using Firebase Admin SDK.
- **User Data:** User profile, roles, and trust score are stored in MongoDB. **Passwords are never stored.**
- **Security:**
  - Service account credentials are loaded from environment variables only.
  - No Firebase Admin logic or secrets in frontend.
  - No database access from frontend.

## Setup
1. Create a `.env` file in `backend/` with:
   - `FIREBASE_SERVICE_ACCOUNT` (base64-encoded JSON)
   - `MONGODB_URI` (your MongoDB connection string)
   - `PORT` (optional, default 3000)
2. Install dependencies:
   ```sh
   npm install
   ```
3. Start the server:
   ```sh
   npm run dev
   ```

## Health Check
- `GET /health` returns `{ status: 'ok' }` if server is running.

## Project Structure
- `src/index.js` — Main entry point
- `src/middleware/` — Authentication middleware
- `src/models/` — Mongoose models
- `src/routes/` — Express routes

---

**See code comments for more details on architecture and security.**
