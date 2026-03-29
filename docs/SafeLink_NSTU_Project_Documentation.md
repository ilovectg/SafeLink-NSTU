# SafeLink NSTU — Project Documentation

## 1. Introduction
SafeLink NSTU is a mobile-based safety application designed for students and teachers of Noakhali Science and Technology University (NSTU). It provides a fast and reliable communication channel during emergencies such as ragging, harassment, medical emergencies, or accidents. The app ensures rapid response, accountability, and user verification for campus safety.

Key Features:
- SOS Trigger via Button, Shake, or Power Button
- Live Photo Capture during Sign-Up
- Automatic GPS location + Optional Pre-Set Building and Floor Selection
- Alerts first sent to Proctorial Body, can be forwarded to Security Body
- Push notifications, SMS backup, and auto hotline call
- Geofencing (alerts only inside NSTU campus)
- Alert History (Pending / Resolved)
- Role-based access (Students / University Authority / Proctorial Body / Security Body)

---

## 2. Functional Requirements (Complete)
| ID | Requirement | Description |
|---:|------------|-------------|
| FR1 | Institutional Email Sign-Up | Users must sign up using official NSTU email (@nstu.student.edu.bd for students, @nstu.edu.bd for authorities) with OTP verification. |
| FR2 | Role Selection | Users select Student or University Authority. If University Authority, they choose Proctorial Body or Security Body. |
| FR3 | Rules & Regulations Agreement | Only Students must agree to Rules & Regulations after sign-up before accessing features. |
| FR4 | 6-Digit Password Policy | Password must be at least 6 digits. |
| FR5 | Secure Login | Login using institutional email and password. Incorrect credentials show error. |
| FR6 | Forgot Password | Users can reset password via OTP to institutional email. |
| FR7 | Pre-Permission Setup | Request location access at first launch for SOS. |
| FR9 | Pre-Set Danger Location | Students can set building name and select floor; skipping allowed. |
| FR10 | SOS Button | Trigger emergency alert immediately with confirmation popup. |
| FR11 | Shake-to-SOS | Shake detection with motion >15 m/s², 3 times in 2–3 seconds, with confirmation popup. |
| FR12 | Volume Button SOS | Press volume button multiple times within timeframe to trigger SOS, with confirmation popup. |
| FR13 | Push Notifications | Alert sent to Proctorial Body with emergency sound. |
| FR14 | SMS Backup | Alert details sent via SMS as backup. |
| FR15 | Automatic Hotline Call | Call emergency hotline if alert not accepted within set timeframe. |
| FR16 | Alert Acceptance Logic | If authority accepts alert → no call. If no response → automatic call. |
| FR17 | Alert Status | Pending: not yet accepted by Proctorial Body. Resolved: accepted and handled. |
| FR18 | Forwarding to Security Body | Proctorial Body can forward alert to Security Body. Security Body only receives alert when forwarded. |
| FR19 | Settings Page | Edit profile. |
| FR20 | Logout Option | Manual logout from the app. |
| FR21 | Alert History | View past alerts with details, including Pending/Resolved/Forwarded status. |
| FR22 | Confirmation Popups | Before sending SOS, confirmation popup ensures no false alarm. |
| FR23 | Geofencing | SOS triggers active only within NSTU campus boundaries. |
| FR24 | Profile Validation | Profile data validated and securely stored for identity verification. |
| FR25 | Background Listener | Volume button and shake detection run even when app is minimized. |
| FR26 | Emergency Call Timeout | Automatic call triggers if Proctorial Body does not respond within configurable timeframe. |
| FR27 | Alert Forwarding Logs | Track forwarding history for accountability. |

---

## 3. Workflow Details

### 3.1 Sign-Up Workflow
1. Install and open app.
2. Pre-Permission Setup: Request location permission.
3. Role Selection: Student or University Authority (Proctorial Body / Security Body).
4. Enter institutional email → OTP verification.
5. Create 6-digit password.
6. Student profile fields: Name, ID, Batch, Session, Mobile Number, Department.
7. Authority profile fields: Name, Position, Mobile Number.
8. Rules & Regulations agreement (Students only).
9. Account created and validated.

### 3.2 Login Workflow
1. Enter email and password.
2. App authenticates credentials.
3. Success → main dashboard.
4. Failure → show error.
5. Forgot Password → reset via OTP.

### 3.3 SOS Workflow
1. Student triggers SOS by:
   - Pressing SOS button
   - Shaking the phone (a > 15 m/s², 3 times within 2–3s)
   - Pressing volume button multiple times within timeframe (e.g., 3 presses in 2–3s)
2. Show confirmation popup; if not cancelled, send SOS.
3. Geofencing: Only works inside NSTU campus.
4. Data collected: Student details, live GPS location, optional pre-set building/floor.
5. Delivery:
   - Push notification to Proctorial Body with emergency sound
   - SMS backup to hotline number
   - Automatic hotline call if alert not accepted within timeframe (default 60s)
6. Alert Acceptance Logic: If accepted, no call; if not, automatic call after timeout.
7. Alert Categorization: Pending, Resolved, Forwarded.
8. Forwarding: Proctorial Body may forward to Security Body; forwarding logged.

### 3.4 Settings & Logout Workflow
1. Open Settings from dashboard.
2. Options: Edit profile, Change password (requires current password), Logout (clears session).

---

## 4. Key Features
- SOS triggers: Button, Shake, Power/Volume Button
- Live Photo Capture during sign-up (face detection for verification)
- Optional Pre-Set Building/Floor Selection
- Push notifications, SMS backup, and auto call
- Two-tier Alert System: Proctorial Body → Security Body
- Geofencing (NSTU campus only)
- Alert History: Pending / Resolved / Forwarded
- Role-Based Dashboards: Students, Proctorial Body, Security Body
- Alert acceptance logic and forwarding logs
- Confirmation popups to prevent false alarms

---

## 5. Technology Stack

### 5.1 Frontend
- Flutter / Dart for Mobile App
- Flutter Widgets for UI
- GPS API for location
- Camera + ML Kit Face Detection for live photo
- Sensor package for shake detection
- Background listener for power/volume button presses
- Push Notifications via Firebase Cloud Messaging (FCM)
- Local Storage: Shared Preferences / SQLite

### 5.2 Backend / Services
- Firebase Cloud Functions OR Node.js + Express.js
- Firebase Firestore / Realtime Database
- Firebase Authentication (email + password + OTP flows)
- SMS/Auto Call via Twilio / Vonage API
- Hosting: Firebase Hosting / Google Cloud / AWS
- Crash & Performance Monitoring: Firebase Crashlytics / Google Cloud Monitoring

---

## Conclusion
SafeLink NSTU provides a reliable, structured, and robust safety solution for students and authorities. It ensures rapid emergency response via multiple SOS triggers, accountability through alert logs and forwarding, and student verification through live photo capture. The system prioritizes safety, reliability, and ease-of-use for a safer campus environment.

---

If you'd like, I can now:
- Review the existing workspace and map files to the architecture above.
- Propose a minimal MVP implementation plan and sprint tasks.
- Scaffold initial Flutter screens and backend stubs.

Please tell me which next step you prefer.
