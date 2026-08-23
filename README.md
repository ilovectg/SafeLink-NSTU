# 🚨 SafeLink NSTU

### A Real-Time Campus Safety & Emergency Response Platform

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Google%20Maps-4285F4?style=for-the-badge&logo=googlemaps&logoColor=white" alt="Google Maps"/>
</p>

<p align="center">
  <b>One Tap. One Alert. Faster Help.</b>
</p>

<p align="center">
  A mobile-first safety platform designed to connect students with university emergency responders through real-time SOS alerts, location tracking, and cloud-powered communication.
</p>

---

## 🛡️ Why SafeLink?

Emergencies on a university campus often require **immediate communication and accurate location information**.

SafeLink NSTU was designed to address this challenge by creating a centralized emergency response platform where students can quickly send an SOS alert while authorized responders can monitor and manage active incidents.

```text
              🚨 EMERGENCY
                    │
                    ▼
             One-Tap SOS
                    │
                    ▼
          📍 Capture Location
                    │
                    ▼
        ☁️ Firebase Real-Time Sync
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
     👨‍🏫 Proctor          🛡️ Security
          │                   │
          └─────────┬─────────┘
                    ▼
             🚑 RESPONSE
```

---

# ✨ Key Features

## 🚨 One-Tap SOS

Students can trigger an emergency alert instantly from the application.

The system creates an alert and begins the emergency communication workflow without requiring a lengthy form.

---

## 📍 Real-Time Location Sharing

When an SOS is triggered, the application captures the student's current location and synchronizes location information through Firebase.

This allows authorized responders to understand **where help is needed**.

---

## 📡 Live Alert Synchronization

Firebase-powered synchronization keeps alert status and emergency information updated in real time.

```text
Student App
     │
     │ SOS
     ▼
Firebase
     │
     ├──────────────► Proctor
     │
     └──────────────► Security
```

---

## 🫨 Shake-to-Trigger SOS

SafeLink supports an optional shake-based emergency trigger, allowing users to activate an SOS without navigating through the application interface.

---

## 🔊 Volume Button Emergency Trigger

The application also supports emergency activation through physical volume-button interactions for situations where accessing the screen may be difficult.

---

## 📳 Set Pulse

For indoor environments, students can optionally provide:

* Building
* Floor
* Risk-area context

This can help responders understand the user's environment when GPS information may be less useful indoors.

The feature is optional and can be skipped.

---

# 👥 Multi-Role Emergency System

SafeLink is designed around different user roles.

```text
                    SafeLink
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
      👨‍🎓 Student    👨‍🏫 Proctor   🛡️ Security
          │            │            │
          │            │            │
       Trigger       Monitor       Monitor
         SOS          Alerts        Alerts
          │            │            │
          └────────────┼────────────┘
                       ▼
                  🚑 Response
```

### 👨‍🎓 Student

* Trigger SOS
* Share location
* Monitor alert status
* Cancel an alert
* Use emergency triggers

### 👨‍🏫 Proctor

* Monitor active incidents
* Review emergency information
* Process alerts
* Respond to student emergencies

### 🛡️ Security

* Monitor emergency alerts
* Access location information
* Manage response workflows

---

# 🔄 Emergency Workflow

The complete SOS workflow is designed to minimize the time between **incident → alert → response**.

```text
01  Student triggers SOS
              │
              ▼
02  Current location captured
              │
              ▼
03  Alert sent to Firebase
              │
              ▼
04  Real-time synchronization
              │
              ▼
05  Authorized responders notified
              │
              ▼
06  Alert accepted / processed
              │
              ▼
07  Emergency response initiated
              │
              ▼
08  Student can cancel the alert
```

---

# 🗺️ Location & Maps

SafeLink integrates location services to provide emergency context.

### Location Technologies

* 📍 Geolocation
* 🧭 Geocoding
* 🗺️ Google Maps
* 🔄 Real-time location synchronization

The application uses:

```text
Geolocator
     ↓
Current Coordinates
     ↓
Geocoding
     ↓
Location Information
     ↓
Google Maps Visualization
```

---

# ☁️ Firebase Architecture

Firebase acts as the cloud backbone of the application.

```text
                       Firebase
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
   🔐 Authentication   🗄️ Firestore      ⚡ Functions
        │                 │                 │
        ▼                 ▼                 ▼
      Users            SOS Alerts       Backend Logic
                          │
                          ▼
                     📡 Messaging
```

### Firebase Services

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Functions
* Firebase Cloud Messaging
* Firebase Local Notifications

---

# 🧩 Technology Stack

### 📱 Mobile Application

* Flutter
* Dart

### ☁️ Backend & Cloud

* Firebase
* Cloud Firestore
* Firebase Authentication
* Cloud Functions
* Firebase Cloud Messaging

### 📍 Location

* Geolocator
* Geocoding
* Google Maps Flutter

### 🔔 Notifications

* Firebase Messaging
* Flutter Local Notifications

---

# 🏗️ Project Architecture

```text
SafeLink-NSTU/
│
├── 📱 lib/
│   └── Flutter application source
│
├── ⚙️ functions/
│   └── Firebase Cloud Functions
│
├── 🖼️ assets/
│   └── Application images & assets
│
├── 🤖 android/
│   └── Android platform configuration
│
├── 🍎 ios/
│   └── iOS platform configuration
│
├── 🌐 web/
│   └── Web platform configuration
│
├── 🐧 linux/
│   └── Linux platform configuration
│
├── 🍎 macos/
│   └── macOS platform configuration
│
├── 🪟 windows/
│   └── Windows platform configuration
│
├── 🧪 test/
│   └── Application tests
│
├── 🔥 firebase.json
├── 🔐 firestore.rules
├── 📦 pubspec.yaml
├── ⚙️ BACKEND_SOS_IMPLEMENTATION.js
└── 📘 README.md
```

---

# 🧠 Core System Components

## 🚨 SOS Engine

Responsible for initiating emergency alerts and coordinating the alert lifecycle.

```text
Trigger
  ↓
Create Alert
  ↓
Attach Location
  ↓
Sync with Firebase
  ↓
Notify Responders
  ↓
Track Status
```

---

## 📍 Location Engine

Responsible for obtaining and processing the user's location.

It integrates:

* Geolocation
* Geocoding
* Maps
* Real-time updates

---

## 🔔 Notification Layer

Notifications help communicate emergency events and status changes to relevant users.

The project combines Firebase Messaging with local notifications for notification handling.

---

## 🔐 Authentication

Firebase Authentication provides the foundation for user identity and role-based access flows.

---

# 🧪 Local Development

## Requirements

Install:

* Flutter SDK
* Dart SDK
* Node.js
* Firebase CLI

---

## 1. Clone

```bash
git clone https://github.com/ilovectg/SafeLink-NSTU.git
```

```bash
cd SafeLink-NSTU
```

---

## 2. Install Flutter Dependencies

```bash
flutter pub get
```

---

## 3. Run the Application

```bash
flutter run
```

For Chrome:

```bash
flutter run -d chrome
```

---

# ⚡ Cloud Functions

Navigate to the functions directory:

```bash
cd functions
```

Install dependencies:

```bash
npm install
```

Start locally:

```bash
npm run start
```

Deploy:

```bash
npm run deploy
```

---

# 🔐 Environment & Security

Before running the application in a real environment, configure the required Firebase credentials and environment-specific settings.

### Never commit:

```text
❌ Private API keys
❌ Service-account credentials
❌ Production secrets
❌ Private Firebase configuration
❌ Sensitive user information
```

Security rules should also be carefully reviewed before production deployment.

---

# 📲 Platform Support

The repository contains platform-specific configurations for:

| Platform   | Support |
| ---------- | ------- |
| 🤖 Android | ✅       |
| 🍎 iOS     | ✅       |
| 🌐 Web     | ✅       |
| 🪟 Windows | ✅       |
| 🐧 Linux   | ✅       |
| 🍎 macOS   | ✅       |

---

# 📸 Screenshots

The repository contains application images under:

```text
assets/images/
```

Additional UI screenshots can be showcased here to demonstrate:

* 🏠 Student dashboard
* 🚨 SOS interface
* 📍 Live location
* 🗺️ Map view
* 👨‍🏫 Proctor dashboard
* 🛡️ Security dashboard
* 🔔 Alert notifications

---

# 🎯 Project Goals

SafeLink NSTU was designed around four core goals:

```text
        🚨 SPEED
           │
           ▼
     Faster emergency
       activation
           │
           ▼
        📍 ACCURACY
           │
           ▼
     Better location
        context
           │
           ▼
        📡 SYNC
           │
           ▼
    Real-time alert
       updates
           │
           ▼
       🛡️ SAFETY
```

---

# 🧠 What This Project Demonstrates

Building SafeLink NSTU provides practical experience with:

* Flutter application development
* Cross-platform development
* Firebase integration
* Cloud Firestore
* Firebase Authentication
* Cloud Functions
* Push notifications
* Real-time data synchronization
* GPS and location services
* Google Maps integration
* Role-based application flows
* Emergency workflow design
* Event-driven backend logic
* Mobile UI/UX development

---

# 🔮 Future Improvements

* [ ] Dedicated emergency response analytics
* [ ] Advanced incident history
* [ ] Automated responder assignment
* [ ] Emergency heatmaps
* [ ] Offline emergency queue
* [ ] Improved indoor positioning
* [ ] More granular role permissions
* [ ] Emergency response time analytics
* [ ] Richer notification preferences
* [ ] Automated testing across supported platforms

---

# 📌 Project Status

```text
🟢 Flutter Application       Implemented
🟢 SOS Workflow              Implemented
🟢 Real-Time Firebase Sync   Implemented
🟢 Location Tracking         Implemented
🟢 Maps Integration          Implemented
🟢 Notifications             Implemented
🟢 Multi-Role Workflow       Implemented
🟢 Emergency Triggers        Implemented
```

---

# 🌸 Why SafeLink Matters

> **Technology should not only make life easier — it should make people safer.**

SafeLink NSTU explores how mobile technology, cloud infrastructure, real-time communication, and location services can work together to create a faster and more connected emergency response experience for a university campus.

---

# 👨‍💻 Project

**SafeLink NSTU**

A Flutter-based campus safety platform developed for **Noakhali Science and Technology University (NSTU)**.

<p align="center">
  <a href="https://github.com/ilovectg/SafeLink-NSTU">
    <img src="https://img.shields.io/badge/View%20Source%20Code-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub"/>
  </a>
</p>

---

<p align="center">

### 🚨 One Tap. One Alert. Faster Help.

</p>
