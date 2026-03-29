# SafeLink OTP Cloud Function

This folder contains a Firebase Cloud Function that listens for new documents in the `email_otps` Firestore collection and sends the OTP to the provided email using SendGrid.

## How it works
- When your Flutter app creates a new `email_otps` document (fields: `email`, `code`, `purpose`, `createdAt`, `expiresAt`), the function triggers on create.
- The function performs simple validation and rate-limiting (to reduce spam/abuse) and sends an email using SendGrid.
- After a successful send, the function sets `sent: true` and `sentAt` on the OTP document.

## Environment variables / config
Set the following so that the function can send emails:

Option A (recommended): Firebase functions config

  firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY" sendgrid.from="no-reply@yourdomain.com"
  firebase deploy --only functions

Option B: Set environment variables on your host (used for local emulation):

  export SENDGRID_API_KEY="..."
  export SENDGRID_FROM="no-reply@yourdomain.com"

## Local testing / emulators
Install dependencies and start the emulator:

  cd functions
  npm install
  npm run start

You can create a test OTP doc with the included script (when connected to emulator or a dev project):

  node scripts/send_test_otp.js your-test-email@domain.com

Then check the function logs in the emulator UI or `firebase emulators:start` console output to confirm the email send behavior.

## Deployment
  cd functions
  npm install
  firebase deploy --only functions

## Notes & Production recommendations
- Use your institutional mail sender (SendGrid verified domain, or SMTP) when sending OTPs.
- Consider moving OTP sending to a more secure backend service if you need higher throughput or custom templates.
- Keep comprehensive logging and add monitoring/alerts for failed sends.
- Do not log OTP codes in production logs.
