// Quick script to create a test OTP document in Firestore (use emulator or real project carefully)
// Usage:
//  node scripts/send_test_otp.js test@example.com

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

async function sendTest(email) {
  const now = new Date();
  const expires = new Date(now.getTime() + 10 * 60 * 1000);
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const doc = {
    email,
    code,
    purpose: 'signup',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(expires),
  };
  const ref = await firestore.collection('email_otps').add(doc);
  console.log('Created OTP doc:', ref.id, 'code (dev only):', code);
}

const email = process.argv[2] || 'test@example.com';
sendTest(email).catch(err => {
  console.error(err);
  process.exit(1);
});