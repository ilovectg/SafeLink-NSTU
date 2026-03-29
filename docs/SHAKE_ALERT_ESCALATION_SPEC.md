# Shake Alert Escalation System - Technical Specification

## Overview
This document outlines the implementation of the **Shake-to-SOS** feature (FR11) with automatic alert escalation as part of the SafeLink NSTU safety application. When a student shakes their phone (motion >15 m/s², 3 times in 2–3 seconds), an SOS alert is triggered and sent to the Proctorial Body with automatic escalation if no response is received.

## Related Requirements
- **FR11:** Shake-to-SOS trigger with confirmation popup
- **FR13:** Push notifications to Proctorial Body with emergency sound
- **FR14:** SMS backup as fallback communication
- **FR15:** Automatic hotline call if alert not accepted within timeframe
- **FR16:** Alert acceptance logic (accepted = no call, no response = automatic call)
- **FR17:** Alert status tracking (Pending/Resolved)
- **FR18:** Forwarding to Security Body
- **FR23:** Geofencing (NSTU campus only)
- **FR25:** Background listener for shake detection

## Feature Requirements

### 1. Background Shake Detection (FR11 + FR25)
- **Trigger:** Phone shake gesture detected (acceleration >15 m/s², 3 shakes within 2-3 seconds)
- **Condition:** Student must be logged in
- **Geofencing:** Only active within NSTU campus boundaries (FR23)
- **State:** App can be in background or foreground
- **Confirmation:** Show confirmation popup before sending (FR22)
- **Action:** If confirmed, send SOS alert to Proctorial Body

### 2. Alert Escalation Timeline (FR13-FR16)

```
Time 0:00  → Shake detected (3x in 2-3s, a>15 m/s²)
           → Confirmation popup shown
           → If confirmed: Send alert to Proctorial Body app
           → Push notification with emergency sound (FR13)
           → SMS backup sent to hotline (FR14)
    ↓
Time 1:00  → No response from Proctorial Body?
           → Job 1: Send SMS to Proctorial Body phone(s)
    ↓
Time 5:00  → Still no response?
           → Job 2: Automatic hotline call (FR15, FR16)
```

## Technical Implementation

### Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Student's Device                          │
├─────────────────────────────────────────────────────────────┤
│  1. ShakeDetectionService (Background/Foreground, FR25)     │
│     ├─> Detects: a > 15 m/s², 3 shakes in 2-3s (FR11)      │
│     ├─> Checks: Geofencing (NSTU campus only, FR23)        │
│     └─> Shows: Confirmation popup (FR22)                    │
│                                                              │
│  2. AlertController                                          │
│     ├─> Collects: Student details, GPS, building/floor     │
│     ├─> Sends alert to Firebase + Backend                   │
│     └─> Saves to local history (FR21)                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
├─────────────────────────────────────────────────────────────┤
│  3. Cloud Function: sendSosAlert                            │
│     ├─> Save alert to Firestore (status: pending, FR17)     │
│     ├─> Send FCM push notification to ALL Proctorial Body   │
│     │   members with emergency sound (FR13)                 │
│     ├─> Send SMS backup to hotline number (FR14)            │
│     └─> Schedule escalation jobs (Cloud Tasks/Scheduler)    │
│                                                              │
│  4. Cloud Function: escalateAlertSMS (triggered at +1 min)  │
│     ├─> Check if alert status is still 'pending' (FR17)     │
│     ├─> If pending: Send SMS to ALL Proctorial Body phones  │
│     └─> Update alert escalation metadata                    │
│                                                              │
│  5. Cloud Function: escalateAlertCall (triggered at +5 min) │
│     ├─> Check if alert status is still 'pending' (FR17)     │
│     ├─> If pending: Initiate call to emergency hotline      │
│     │   (FR15, FR16)                                         │
│     └─> Update alert status to 'escalated'                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Proctorial Body Members' Devices                │
├─────────────────────────────────────────────────────────────┤
│  6. Push Notification (FCM) → Alert Dialog (FR13)           │
│     └─> "Accept" button → Updates status to 'accepted'      │
│         (stops escalation, FR16)                             │
│                                                              │
│  7. "Forward to Security" button (FR18)                     │
│     └─> Send notification to Security Body                  │
│         Update status to 'forwarded' + log forwarding       │
│                                                              │
│  8. SMS Notification (if no response after 1 min, FR14)     │
│                                                              │
│  9. Automatic Hotline Call (if no response after 5 min,     │
│     FR15, FR16)                                              │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Background Shake Detection (FR11, FR25)
**Status:** ✅ PARTIALLY IMPLEMENTED (Testing Phase)

**Files Created/Modified:**
- ✅ `lib/core/services/shake_detection_service.dart` (Created - FR11 parameters)
- ✅ `lib/presentation/home/home_screen.dart` (Modified - Service initialization)
- ✅ `docs/SHAKE_SERVICE_INTEGRATION.md` (Documentation created)
- 🔲 `lib/core/services/geofencing_service.dart` (NEW - for FR23 campus boundary check)
- 🔲 `lib/core/services/background_service.dart` (NEW - for background execution)
- 🔲 `lib/presentation/widgets/confirmation_dialog.dart` (NEW - for FR22)
- 🔲 `android/app/src/main/AndroidManifest.xml` (Add permissions)
- 🔲 `ios/Runner/Info.plist` (Add background modes)

**Current Implementation:**
- ✅ Shake detection: acceleration > 15 m/s² (1.53 G), 3 times within 2-3 seconds (FR11)
- ✅ Role-based activation: ONLY for students
- ✅ Context-safe dialog display
- ✅ Singleton pattern (no provider issues)
- ✅ Automatic start in HomeScreen
- ✅ Automatic stop on screen dispose
- ⏳ Shows test popup (not integrated with alert system yet)

**Dependencies Required:**
```yaml
dependencies:
  shake: ^3.0.0                       # ✅ Already added
  geolocator: ^14.0.2                 # ✅ Already added (for geofencing)
  flutter_background_service: ^5.0.0  # For background execution
  workmanager: ^0.5.2                 # Alternative: scheduled background tasks
```

**Next Steps for Phase 1:**
1. ✅ Detect shake with FR11 parameters (DONE)
2. 🔲 Add geofencing check (FR23)
3. 🔲 Add confirmation popup (FR22)
4. 🔲 Integrate with AlertController to trigger actual SOS
5. 🔲 Implement background service (FR25)
6. 🔲 Request necessary permissions (activity recognition, wake lock, location)

### Phase 2: Alert Escalation Backend (FR13-FR16)
**Files to Create:**
- 🔲 `functions/src/alerts/escalateAlertSMS.js`
- 🔲 `functions/src/alerts/escalateAlertCall.js`
- 🔲 `functions/src/utils/scheduleTasks.js`
- 🔲 `functions/src/utils/sendSMS.js`
- 🔲 `functions/src/utils/makeCall.js`
- 🔲 Update `functions/index.js`

**Firebase Services Required:**
- Cloud Functions (already setup)
- Cloud Firestore (already setup)
- Firebase Cloud Messaging / FCM (for FR13 push notifications)
- Cloud Tasks or Cloud Scheduler (NEW - for delayed jobs)
- Twilio API (for SMS backup FR14, auto call FR15)

**Backend Functions:**

#### Function 1: `sendSosAlert` (MODIFY EXISTING)
```javascript
exports.sendSosAlert = functions.https.onRequest(async (req, res) => {
  const { studentId, studentName, location, latitude, longitude, 
          department, session, phone, email, building, floor } = req.body;
  
  // 1. Save alert to Firestore with status: 'pending' (FR17)
  const alertRef = await db.collection('alerts').add({
    studentId, studentName, location, latitude, longitude,
    department, session, phone, email, building, floor,
    status: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    smsEscalated: false,
    callEscalated: false,
    acceptedBy: null,
    forwardedTo: null
  });
  
  // 2. Get ALL Proctorial Body members
  const proctors = await db.collection('users')
    .where('role', '==', 'proctorial body')
    .get();
  
  // 3. Send FCM push notification to ALL proctors with emergency sound (FR13)
  const tokens = proctors.docs.map(doc => doc.data().fcmToken).filter(Boolean);
  await sendPushNotification(tokens, {
    title: '🚨 EMERGENCY ALERT',
    body: `${studentName} needs help at ${location}`,
    sound: 'emergency_alert.mp3', // Custom emergency sound
    data: { alertId: alertRef.id, type: 'sos_shake' }
  });
  
  // 4. Send SMS backup to hotline number (FR14)
  const hotlineNumber = functions.config().hotline.number;
  await sendSMS(hotlineNumber, 
    `EMERGENCY: ${studentName} (${studentId}) at ${location}. GPS: ${latitude},${longitude}`
  );
  
  // 5. Schedule escalation jobs (FR15, FR16)
  await scheduleEscalationSMS(alertRef.id, proctors, 1); // 1 minute
  await scheduleEscalationCall(alertRef.id, hotlineNumber, 5); // 5 minutes (FR26)
  
  res.status(200).send({ success: true, alertId: alertRef.id });
});
```

#### Function 2: `escalateAlertSMS` (NEW - FR14)
```javascript
exports.escalateAlertSMS = functions.pubsub
  .schedule('every 1 minutes') // Check every minute
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const oneMinuteAgo = new admin.firestore.Timestamp(now.seconds - 60, now.nanoseconds);
    
    // Find alerts pending for 1+ minutes and not yet SMS escalated
    const pendingAlerts = await db.collection('alerts')
      .where('status', '==', 'pending')
      .where('smsEscalated', '==', false)
      .where('createdAt', '<=', oneMinuteAgo)
      .get();
    
    for (const doc of pendingAlerts.docs) {
      const alert = doc.data();
      
      // Get ALL Proctorial Body phone numbers
      const proctors = await db.collection('users')
        .where('role', '==', 'proctorial body')
        .get();
      
      // Send SMS to ALL proctor phones
      for (const proctor of proctors.docs) {
        const phone = proctor.data().phone;
        await sendSMS(phone, 
          `URGENT: ${alert.studentName} emergency alert not responded. Location: ${alert.location}`
        );
      }
      
      // Update alert
      await doc.ref.update({ 
        smsEscalated: true,
        smsEscalatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ SMS escalation sent for alert ${doc.id}`);
    }
  });
```

#### Function 3: `escalateAlertCall` (NEW - FR15, FR16)
```javascript
exports.escalateAlertCall = functions.pubsub
  .schedule('every 1 minutes') // Check every minute
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const fiveMinutesAgo = new admin.firestore.Timestamp(now.seconds - 300, now.nanoseconds);
    
    // Find alerts pending for 5+ minutes and not yet call escalated (FR26)
    const pendingAlerts = await db.collection('alerts')
      .where('status', '==', 'pending')
      .where('callEscalated', '==', false)
      .where('createdAt', '<=', fiveMinutesAgo)
      .get();
    
    for (const doc of pendingAlerts.docs) {
      const alert = doc.data();
      
      // Make call to emergency hotline (FR15, FR16)
      const hotlineNumber = functions.config().hotline.number;
      await makeCall(hotlineNumber, {
        message: `Emergency alert for ${alert.studentName}, student ID ${alert.studentId}, at ${alert.location}. GPS coordinates: ${alert.latitude}, ${alert.longitude}. This is an automated emergency call from SafeLink NSTU.`
      });
      
      // Update alert
      await doc.ref.update({ 
        status: 'escalated',
        callEscalated: true,
        callEscalatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`✅ Call escalation initiated for alert ${doc.id}`);
    }
  });
```

### Phase 3: Proctor Response Handling (FR16, FR18)
**Files to Modify:**
- 🔲 `lib/presentation/home/controllers/alert_response_service.dart`
- 🔲 `lib/presentation/home/alert_detail_screen.dart`
- 🔲 `functions/src/alerts/acceptAlert.js` (NEW backend function)
- 🔲 `functions/src/alerts/forwardToSecurity.js` (NEW backend function)

**Implementation:**
1. Add "Accept Alert" button in proctor's alert detail screen
   - When clicked, update alert status to "accepted" in Firestore (FR16)
   - This stops escalation jobs from triggering (no SMS, no call)
   - Record which proctor accepted (acceptedBy, acceptedAt)

2. Add "Forward to Security Body" button (FR18)
   - Send notification to ALL Security Body members
   - Update alert status to "forwarded"
   - Log forwarding history for accountability (FR27)
   - Security Body can then accept/resolve the alert

3. Mark as "Resolved" button
   - Update alert status to "resolved" (FR17)
   - Add resolution notes/comments

### Phase 4: Alert Status Tracking (FR17, FR18, FR27)
**Firestore Schema Update:**
```javascript
// Collection: alerts/{alertId}
{
  // Student information
  studentId: string,
  studentName: string,
  studentPhone: string,
  studentEmail: string,
  department: string,
  session: string,
  
  // Location data (FR9, FR23)
  latitude: number,
  longitude: number,
  location: string,  // Address from geocoding
  building: string | null,  // Pre-set building (optional)
  floor: string | null,     // Pre-set floor (optional)
  
  // Alert metadata
  type: 'shake' | 'button' | 'volume',  // Trigger type
  status: 'pending' | 'accepted' | 'resolved' | 'escalated' | 'forwarded',  // FR17
  createdAt: Timestamp,
  
  // Escalation tracking (FR14, FR15, FR16)
  smsEscalated: boolean,
  smsEscalatedAt: Timestamp | null,
  callEscalated: boolean,
  callEscalatedAt: Timestamp | null,
  
  // Response tracking (FR16)
  acceptedBy: string | null,  // Proctor user ID
  acceptedByName: string | null,
  acceptedAt: Timestamp | null,
  
  // Forwarding tracking (FR18, FR27)
  forwardedTo: 'security body' | null,
  forwardedBy: string | null,  // Proctor user ID who forwarded
  forwardedByName: string | null,
  forwardedAt: Timestamp | null,
  forwardedReason: string | null,  // Optional reason for forwarding
  
  // Resolution tracking (FR17)
  resolvedBy: string | null,  // User ID (proctor or security)
  resolvedByName: string | null,
  resolvedAt: Timestamp | null,
  resolutionNotes: string | null
}

// Collection: users/{userId} - Proctorial Body / Security Body
{
  email: string,
  role: 'student' | 'proctorial body' | 'security body',
  name: string,
  phone: string,  // For SMS/call escalation (FR14, FR15)
  position: string,  // For authorities
  fcmToken: string | null,  // For push notifications (FR13)
  isActive: boolean,  // On-duty status
  createdAt: Timestamp
}
```

## Dependencies to Add

### pubspec.yaml
```yaml
dependencies:
  shake: ^3.0.0  # ✅ Already added
  
  # Background execution
  flutter_background_service: ^5.0.0
  # OR
  workmanager: ^0.5.2
  
  # Permissions
  permission_handler: ^12.0.1  # ✅ Already added
  
  # Phone/SMS (if handling on client side)
  url_launcher: ^6.3.1  # ✅ Already added
  flutter_phone_direct_caller: ^2.1.1  # For emergency call

dev_dependencies:
  build_runner: ^2.4.13  # ✅ Already added
```

### package.json (Firebase Functions)
```json
{
  "dependencies": {
    "firebase-functions": "^4.5.0",
    "firebase-admin": "^12.0.0",
    "twilio": "^4.19.0",  // NEW - For SMS and calls
    "@google-cloud/tasks": "^4.0.0"  // NEW - For scheduled jobs
  }
}
```

## Required Third-Party Services

### 1. Twilio (Recommended)
**Purpose:** Send SMS and make phone calls
**Setup:**
- Create Twilio account: https://www.twilio.com/
- Get API credentials (Account SID, Auth Token)
- Buy a Twilio phone number
- Store credentials in Firebase Config:
  ```bash
  firebase functions:config:set twilio.account_sid="YOUR_SID"
  firebase functions:config:set twilio.auth_token="YOUR_TOKEN"
  firebase functions:config:set twilio.phone_number="YOUR_NUMBER"
  ```

**Cost:** ~$1/month + $0.0075 per SMS + $0.013/min for calls

### Alternative: Firebase Extensions
- **Trigger Email from Firestore** (free, email only)
- **Send Messages with Twilio** (SMS, paid)

## Permissions Required

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<!-- Background execution -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

<!-- Phone/SMS (optional, if handling on client) -->
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.SEND_SMS" />
```

### iOS (ios/Runner/Info.plist)
```xml
<!-- Background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>processing</string>
</array>
```

## Security Considerations

1. **Rate Limiting:** Prevent spam alerts (FR22, FR25)
   - Max 1 shake alert per 30 seconds per student
   - Store last alert timestamp in SharedPreferences
   - Show toast message if user tries to trigger too frequently

2. **Student Verification:** 
   - Only students can trigger shake alerts
   - Check user role before initializing ShakeDetectionService
   - Institutional email verification (FR1) ensures only NSTU students

3. **Geofencing Protection:** (FR23)
   - Shake detection only works within NSTU campus boundaries
   - Use polygon geofencing to define campus area
   - Show message if user tries to trigger SOS outside campus

4. **Confirmation Popup:** (FR22)
   - Always show confirmation before sending alert
   - Prevents accidental/false alarms
   - 5-second auto-cancel timer option

5. **Proctor Phone Privacy:**
   - Store proctor phone numbers securely in Firestore
   - Use Firebase Security Rules to protect access
   - Only backend functions can read phone numbers

6. **SMS/Call Costs:**
   - Monitor Twilio usage to prevent abuse
   - Set daily limits in Twilio console
   - Log all SMS/calls for audit trail

7. **Alert History Security:** (FR21)
   - Students can only view their own alert history
   - Proctorial Body sees all alerts
   - Security Body sees only forwarded alerts (FR18)

8. **Background Service Battery:**
   - Optimize shake detection to minimize battery drain
   - Use efficient sensor sampling rate
   - Stop background service when user logs out

## Testing Strategy

### Unit Tests
- ✅ Shake detection triggers correctly
- ✅ Background service stays alive
- ✅ Alert escalation logic (1 min, 5 min)

### Integration Tests
- ✅ End-to-end alert flow
- ✅ Proctor receives push notification
- ✅ SMS sent after 1 minute (no response)
- ✅ Call made after 5 minutes (no response)
- ✅ Escalation stops when proctor accepts

### Manual Testing
- Test on real devices (Android & iOS)
- Test with app in background
- Test with phone locked
- Test SMS/call delivery

## Implementation Timeline

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | Background shake detection | 2-3 days |
| Phase 2 | Backend escalation functions | 3-4 days |
| Phase 3 | Proctor response UI | 1-2 days |
| Phase 4 | Testing & refinement | 2-3 days |
| **Total** | | **8-12 days** |

## Next Steps

1. ✅ Add `shake` dependency (DONE)
2. ✅ Create `ShakeDetectionService` (DONE)
3. 🔲 Decide on background service approach:
   - Option A: `flutter_background_service` (more reliable)
   - Option B: `workmanager` (lighter weight)
4. 🔲 Setup Twilio account for SMS/calls
5. 🔲 Implement backend escalation functions
6. 🔲 Add proctor response handling
7. 🔲 Test end-to-end flow

## Questions to Address

1. **Shake Detection Sensitivity:**
   - Current spec: acceleration > 15 m/s², 3 shakes in 2-3 seconds (FR11)
   - Should we make threshold configurable per device?
   - Some devices may need calibration

2. **Background Service Approach:**
   - Should shake detection work when app is completely killed? (Very battery intensive)
   - Or only when app is in background but not killed? (More practical, FR25)
   - Recommended: Only when app is in background/foreground, not when killed

3. **SMS/Call Provider:**
   - Use Twilio (most reliable, ~$1/month + usage fees)?
   - Use alternative (Firebase SMS extension, local carrier)?
   - Recommended: Twilio for reliability

4. **Geofencing Campus Boundaries:** (FR23)
   - Need precise GPS coordinates for NSTU campus polygon
   - Define entry/exit points
   - Buffer zone (e.g., 50m inside boundary to account for GPS drift)

5. **Multiple Proctors Coordination:**
   - ALL proctors receive push notification (FR13)
   - First to accept stops escalation (FR16)
   - How to handle if multiple proctors try to accept simultaneously?
   - Firestore transaction to ensure only one acceptance

6. **Emergency Hotline Number:**
   - What is the official NSTU emergency hotline number? (FR15)
   - Should there be different numbers for different types of emergencies?
   - Should we call Proctorial Office directly or campus security?

7. **Confirmation Popup Timeout:** (FR22)
   - Current: user must confirm manually
   - Should we add auto-send after X seconds if no response?
   - Or always require manual confirmation to prevent false alarms?
   - Recommended: Always require manual confirmation

8. **Alert Forwarding Logic:** (FR18)
   - Can Proctorial Body forward before accepting?
   - Or must they accept first, then forward?
   - Recommended: Allow forwarding at any time for faster response

9. **Volume Button SOS:** (FR12)
   - Not yet implemented in this spec
   - Should this also trigger the same escalation workflow?
   - Recommended: Yes, same workflow for all trigger types

10. **Testing on Campus:**
    - How to test without triggering real alerts?
    - Need a "Test Mode" toggle for development?
    - Geofencing test: how to simulate being on campus during development?

---

**Document Version:** 2.0  
**Created:** January 8, 2026  
**Updated:** January 8, 2026  
**Author:** GitHub Copilot  
**Status:** Draft - Aligned with SafeLink NSTU Requirements  
**Related Documents:** 
- [SafeLink NSTU Project Documentation](./SafeLink_NSTU_Project_Documentation.md)
- [Firebase Functions Documentation](./FIREBASE_FUNCTIONS.md)
