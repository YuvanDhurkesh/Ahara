// Firebase Admin SDK initialization
// Loads service account from environment variable for security
// Never hardcode secrets or include in frontend

const admin = require('firebase-admin');

// Service account JSON is expected as a base64-encoded string in env
const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT;
if (!serviceAccountBase64) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT env variable is required');
}

let serviceAccount;
try {
  serviceAccount = JSON.parse(Buffer.from(serviceAccountBase64, 'base64').toString('utf8'));
} catch (err) {
  throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT: ' + err.message);
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

module.exports = admin;
