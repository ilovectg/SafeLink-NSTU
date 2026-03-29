# Firebase Cloud Functions (OTP email sender)

Overview
--------
This project includes a Cloud Function in `functions/` that listens for new OTP documents written to Firestore collection `email_otps` and sends the OTP to the user's institutional email using SendGrid.

Files
-----
- `functions/index.js` — Cloud Function implementation (sendSignupOtpEmail)
- `functions/package.json` — Node dependencies and scripts
- `functions/README.md` — local run & deploy instructions

Environment / Deployment
------------------------
1. Install dependencies:
   ```bash
   cd functions
   npm install
   ```
2. Configure SendGrid and sender email (recommended using Firebase functions config):
   ```bash
   firebase functions:config:set sendgrid.api_key="YOUR_SENDGRID_API_KEY" sendgrid.from="no-reply@yourdomain.com"
   ```
3. Deploy to Firebase:
   ```bash
   firebase deploy --only functions
   ```

Local testing
-------------
Use the Firebase emulator to test function locally:

  npm run start

Then write a document into the emulated Firestore `email_otps` collection with fields: `email`, `code`, `purpose`, `createdAt` (serverTimestamp), `expiresAt`.

Production notes
----------------
- The function includes a basic rate-limit (max 5 OTPs in a 10 minute window) and marks docs with `sent` or `rateLimited`.
- You should integrate a verified sender domain for SendGrid and avoid logging OTPs in production logs.
- Consider adding more robust anti-abuse measures (IP/email rate limits, CAPTCHA for writes, reCAPTCHA on signup), and monitoring/alerts for send failures.

Security recommendations
------------------------
- Do **not** write OTP codes directly from the client in production if you can avoid it; use a **Callable Cloud Function** instead so your SendGrid key and logic remain server-side.
- Restrict Firestore write rules: only allow OTP doc creation for unauthenticated flows if accompanied by a proof (reCAPTCHA token) or route OTP requests through a callable function.
- Log failures but never log the OTP code value in production logs. Keep logs minimal and audited.
- Implement more sophisticated rate-limiting and blocking via Firestore counters or an external service to prevent enumeration or brute-force.
- Clean up old/expired OTP docs regularly (e.g., via a scheduled Cloud Function) to avoid storage bloat and to ensure expired tokens are removed.

If you'd like, I can implement a callable Cloud Function version and update the Flutter `sendSignupOtp` flow to call the function instead of writing doc directly.
Recommendation: Use a callable function for OTP requests
------------------------------------------------------
Writing OTP docs directly from the client works, but exposes your Firestore write endpoints to abuse. A safer pattern is to expose a **Callable Cloud Function** that:

- verifies caller identity / recaptcha,
- rate-limits requests server-side,
- writes the OTP doc and/or directly sends the email (keeping your SendGrid API key secret), and
- returns a safe response to the client.

I implemented a callable Cloud Function `requestOtp` and updated the Flutter `AuthController.sendSignupOtp` method to call it instead of writing `email_otps` from the client.

### Creating staff accounts (proctorial/security)
You can pre-create staff accounts using the included admin script. Run it from a trusted environment with admin credentials (service account or from Cloud Functions admin environment):

  cd functions
  node scripts/create_staff_accounts.js

This script will create example accounts:
- `proctor@nstu.edu.bd` (role: `proctorial`)
- `security@nstu.edu.bd` (role: `security`)

Change passwords and emails as needed and secure the script separately. Staff accounts will be stored in Firebase Auth and a `users/{uid}` document with the `role` field set.