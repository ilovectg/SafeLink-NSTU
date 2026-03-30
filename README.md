# SafeLink NSTU

SafeLink NSTU is a dedicated mobile-based student safety application. This system ensures faster communication between students and university authorities during emergencies. Students can instantly trigger an SOS alert in critical situations. SafeLink NSTU aims to create a safer campus environment by leveraging technology, ensuring that every student can quickly receive help when they need it most.

## 🚨 Problem Statement

The current system for reporting and responding to student emergencies at Noakhali Science and Technology University (NSTU) is entirely manual, leading to serious inefficiencies and delays in critical situations. When emergencies such as ragging, harassment, or other incidents occur, students have to contact Teachers, Proctor Office or call them directly, a process that is slow and unreliable.

There is no centralized platform to collect incident information, verify users, track alerts, or maintain accountability of responses. This lack of a streamlined system creates confusion about who should respond, increases response times, and lowers students' confidence in campus safety. SafeLink NSTU solves this by enabling one-tap SOS activation with real-time location and alert updates.

## 💡 Solution Overview

SafeLink NSTU offers a fast and user-friendly safety workflow that allows users to:

- Trigger SOS alerts instantly
- Share live location in real time
- Notify responders through cloud-backed alert flows
- Track and control alert status
- Cancel alerts when the situation is safe

The system is built for real-time performance and future scalability.

## ✨ Features

- One-tap SOS activation: Instantly send an emergency alert with a single tap.
- Real-time live location sharing: Captures and updates the student's current location.
- Set Pulse feature: For indoor scenarios, students can optionally pre-select building and floor details to accelerate emergency context capture when entering potentially risky areas. This step is optional and can be skipped.
- Firebase-powered live backend sync: Alert events and status changes are updated instantly.
- Emergency contact escalation support: Supports SMS and call based escalation workflows.
- Alert status monitoring and maintenance: The Proctorial and Security Bodies can monitor and manage active SOS alerts.
- Multi-role dashboard support: Includes role-based flows such as student, proctor, and security views.
- Shake-trigger integration: Optional shake-based trigger support for quick emergency activation.
- Volume button emergency trigger: Quick SOS activation using physical volume button press for hands-free operation.

## 🛠️ Technologies Used

- Frontend app development: Flutter (Dart)
- Backend services: Firebase (Cloud Firestore, Authentication, Cloud Functions, Messaging)
- Real-time alert and status updates: Firebase services
- Location services: Geolocator and Geocoding
- Map and location visualization: Google Maps Flutter
- Notification handling: Firebase Messaging and Flutter Local Notifications

## 📊 System Workflow

1. User triggers SOS from the app.
2. System captures current location.
3. Alert data is sent to Firebase in real time.
4. Emergency status and location updates are synced instantly.
5. Responders can process, accept, or reject alerts.
6. User can cancel SOS alert to prevent false alarm.

## Local Development Setup

### Prerequisites

- Flutter SDK installed
- Dart SDK
- Node.js
- Firebase CLI

### Clone and install Flutter dependencies

```bash
git clone https://github.com/ilovectg/SafeLink-NSTU.git
cd SafeLink-NSTU
flutter pub get
```

### Run the app

```bash
flutter run
```

Example:

```bash
flutter run -d chrome
```

### Setup and run Cloud Functions locally

```bash
cd functions
npm install
npm run start
```

### Deploy Cloud Functions

```bash
cd functions
npm run deploy
```

## Environment and Secrets

Configure Firebase credentials and environment-specific settings before deployment.

## APK File

Download link: https://github.com/ilovectg/SafeLink-NSTU/releases
