
// Authentication middleware for Express
//
// Why? Backend must verify Firebase ID tokens to ensure requests are from real users.
//      This keeps all sensitive checks server-side (never trust client alone).
//      Only verified users can access protected routes.

const admin = require('../firebaseAdmin');

module.exports = async function firebaseAuthMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }
  const idToken = authHeader.split(' ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};
