# Optimized Escalation Workflow - SafeLink NSTU

## 🚀 Overview

This document describes the **optimized escalation workflow** that uses **Cloud Tasks** for on-demand scheduled execution instead of wasteful periodic checks.

---

## ❌ OLD APPROACH (Wasteful)

### Problems:
- Scheduled functions run **every 1 minute** (1,440 times/day each)
- **2 functions** = **2,880 invocations/day**
- Runs even when **no alerts exist**
- Wastes resources and accumulates unnecessary costs

```javascript
// OLD: Runs every 1 minute, always
exports.escalateAlertSMS = functions.pubsub.schedule('every 1 minutes')...
exports.escalateAlertCall = functions.pubsub.schedule('every 1 minutes')...
```

### Cost Analysis (Old):
- 2,880 invocations/day × 30 days = **86,400 invocations/month**
- Firebase free tier: 2M invocations/month (✅ within limit)
- **But still wasteful!** 86,400 checks for potentially 0 alerts

---

## ✅ NEW APPROACH (Optimal)

### Benefits:
- Tasks scheduled **ONLY when alert is created**
- No periodic checks - runs **on-demand**
- Automatically cancelled if proctor accepts alert
- Runs **only 2 times per actual alert** (SMS task + Call task)

### Architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                        ALERT CREATED (T+0)                      │
│                     sendSosAlert() triggered                    │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ├─► Send push notifications to all proctors
                     │
                     ├─► Store alert in Firestore with:
                     │   - status: 'pending'
                     │   - smsEscalated: false
                     │   - callEscalated: false
                     │
                     ├─► Schedule Cloud Task for T+1 minute
                     │   └─► processEscalationSMS (alertId)
                     │       ├─ Stores task name in alert.smsEscalationTaskName
                     │       └─ Can be cancelled if proctor accepts
                     │
                     └─► Schedule Cloud Task for T+5 minutes
                         └─► processEscalationCall (alertId)
                             ├─ Stores task name in alert.callEscalationTaskName
                             └─ Can be cancelled if proctor accepts

┌─────────────────────────────────────────────────────────────────┐
│                   T+1 MINUTE: SMS ESCALATION                    │
│              processEscalationSMS HTTP endpoint                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ├─► Check alert status:
                     │   └─ If accepted/rejected → SKIP (exit early)
                     │
                     ├─► Get all proctor phone numbers
                     │
                     ├─► Send SMS to ALL proctors via Twilio
                     │   └─ Message: Student name, ID, location, alert ID
                     │
                     └─► Update alert:
                         └─ smsEscalated: true
                         └─ smsEscalatedAt: timestamp

┌─────────────────────────────────────────────────────────────────┐
│                  T+5 MINUTES: CALL ESCALATION                   │
│              processEscalationCall HTTP endpoint                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ├─► Check alert status:
                     │   └─ If accepted/rejected → SKIP (exit early)
                     │
                     ├─► Make Twilio call to emergency hotline
                     │   └─ Voice message: Student details, GPS coords
                     │
                     └─► Update alert:
                         └─ status: 'escalated'
                         └─ callEscalated: true
                         └─ callEscalatedAt: timestamp

┌─────────────────────────────────────────────────────────────────┐
│              PROCTOR ACCEPTS ALERT (Any time)                   │
│                  acceptAlert() triggered                        │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ├─► Cancel SMS escalation task (if not executed)
                     │   └─ tasksClient.deleteTask(smsEscalationTaskName)
                     │
                     ├─► Cancel call escalation task (if not executed)
                     │   └─ tasksClient.deleteTask(callEscalationTaskName)
                     │
                     └─► Update alert:
                         └─ status: 'accepted'
                         └─ escalationsCancelled: true
```

---

## 📊 Cost Comparison

### Scenario: 10 alerts per day

**Old Approach:**
- SMS function: 1,440 invocations/day (runs every minute)
- Call function: 1,440 invocations/day (runs every minute)
- **Total: 2,880 invocations/day** (regardless of alert count)

**New Approach:**
- SMS task: 10 invocations/day (one per alert)
- Call task: 10 invocations/day (one per alert)
- **Total: 20 invocations/day**

**Savings: 2,880 → 20 = 99.3% reduction! 🎉**

### Scenario: 0 alerts per day

**Old Approach:**
- SMS function: 1,440 invocations/day
- Call function: 1,440 invocations/day
- **Total: 2,880 invocations/day** (still running!)

**New Approach:**
- **Total: 0 invocations/day** (no alerts = no tasks)

**Savings: 100% when no alerts! 🎉**

---

## 🔧 Implementation Details

### 1. Cloud Tasks Setup

```javascript
const {CloudTasksClient} = require('@google-cloud/tasks');
const tasksClient = new CloudTasksClient();

const project = 'safe-93f85';
const location = 'us-central1'; // Firebase Functions region
const queue = 'alert-escalation-queue';
```

### 2. Schedule Task Function

```javascript
async function scheduleEscalationTask(alertId, delaySeconds, taskType) {
  const parent = tasksClient.queuePath(project, location, queue);
  
  const task = {
    httpRequest: {
      httpMethod: 'POST',
      url: `https://us-central1-${project}.cloudfunctions.net/${taskType}`,
      headers: {'Content-Type': 'application/json'},
      body: Buffer.from(JSON.stringify({alertId})).toString('base64'),
    },
    scheduleTime: {
      seconds: Math.floor(Date.now() / 1000) + delaySeconds,
    },
  };
  
  const [response] = await tasksClient.createTask({parent, task});
  return response.name;
}
```

### 3. Modified sendSosAlert

```javascript
// Schedule SMS escalation for T+1 minute
const smsTaskName = await scheduleEscalationTask(
  alertRef.id, 
  60, 
  'processEscalationSMS'
);

// Schedule call escalation for T+5 minutes
const callTaskName = await scheduleEscalationTask(
  alertRef.id, 
  300, 
  'processEscalationCall'
);

// Store task names for cancellation
await alertRef.update({
  smsEscalationTaskName: smsTaskName,
  callEscalationTaskName: callTaskName,
});
```

### 4. HTTP Endpoint: processEscalationSMS

```javascript
exports.processEscalationSMS = functions.https.onRequest(async (req, res) => {
  const {alertId} = req.body;
  
  // Get alert
  const alertDoc = await db.collection('proctorial_alerts').doc(alertId).get();
  const alert = alertDoc.data();
  
  // Check if still pending
  if (alert.status !== 'pending') {
    return res.status(200).json({skipped: true}); // Exit early!
  }
  
  // Send SMS to all proctors
  // ... Twilio SMS logic
  
  // Update alert
  await alertDoc.ref.update({
    smsEscalated: true,
    smsEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  return res.status(200).json({success: true});
});
```

### 5. Task Cancellation in acceptAlert

```javascript
// Cancel SMS task if not executed
if (alertData.smsEscalationTaskName) {
  try {
    await tasksClient.deleteTask({name: alertData.smsEscalationTaskName});
    console.log('✅ SMS escalation task cancelled');
  } catch (error) {
    console.log('⚠️ Could not cancel SMS task (may have executed)');
  }
}

// Cancel call task if not executed
if (alertData.callEscalationTaskName) {
  try {
    await tasksClient.deleteTask({name: alertData.callEscalationTaskName});
    console.log('✅ Call escalation task cancelled');
  } catch (error) {
    console.log('⚠️ Could not cancel call task (may have executed)');
  }
}
```

---

## 📋 Deployment Checklist

### 1. Google Cloud Console Setup

```bash
# Enable Cloud Tasks API
https://console.cloud.google.com/apis/library/cloudtasks.googleapis.com?project=safe-93f85

# Create queue (or use default queue)
gcloud tasks queues create alert-escalation-queue \
  --location=us-central1 \
  --project=safe-93f85
```

### 2. Firebase Functions Configuration

```bash
# Set emergency hotline number
firebase functions:config:set hotline.number="+8801XXXXXXXXX"

# View config
firebase functions:config:get
```

### 3. Deploy Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 4. Grant Permissions

Cloud Tasks needs permission to invoke HTTP functions:

```bash
# Get Cloud Tasks service account
gcloud tasks queues describe alert-escalation-queue \
  --location=us-central1 \
  --project=safe-93f85

# Grant invoker role to service account
gcloud functions add-iam-policy-binding processEscalationSMS \
  --region=us-central1 \
  --member=serviceAccount:service-[PROJECT_NUMBER]@gcp-sa-cloudtasks.iam.gserviceaccount.com \
  --role=roles/cloudfunctions.invoker

gcloud functions add-iam-policy-binding processEscalationCall \
  --region=us-central1 \
  --member=serviceAccount:service-[PROJECT_NUMBER]@gcp-sa-cloudtasks.iam.gserviceaccount.com \
  --role=roles/cloudfunctions.invoker
```

---

## 🧪 Testing Plan

### Test 1: Normal Escalation (No Response)

1. Create alert via app
2. Verify push notification sent immediately
3. **Wait 1 minute** → Verify SMS sent to all proctors
4. **Wait 5 minutes** → Verify call made to hotline
5. Check Firestore:
   - `smsEscalated: true`
   - `callEscalated: true`
   - `status: 'escalated'`

### Test 2: Early Acceptance (Cancel Tasks)

1. Create alert via app
2. **Accept alert within 1 minute**
3. Verify:
   - SMS task cancelled (no SMS sent)
   - Call task cancelled (no call made)
   - `escalationsCancelled: true`
   - `status: 'accepted'`

### Test 3: Accept After SMS (Cancel Call Only)

1. Create alert via app
2. **Wait 2 minutes** (SMS sent)
3. **Accept alert** (before 5 minutes)
4. Verify:
   - SMS was sent
   - Call task cancelled (no call made)
   - `smsEscalated: true`
   - `callEscalated: false`
   - `status: 'accepted'`

---

## 🔐 Security Considerations

### 1. Twilio Credentials

**Current:** Hardcoded in `index.js` ❌

**Better:** Use Firebase Functions config or Secret Manager:

```bash
# Option 1: Functions config
firebase functions:config:set twilio.account_sid="ACxxxx" twilio.auth_token="xxxx"

# Option 2: Google Secret Manager (recommended)
gcloud secrets create twilio-account-sid --data-file=-
gcloud secrets create twilio-auth-token --data-file=-
```

### 2. HTTP Endpoint Security

Current endpoints are **publicly accessible**. Add authentication:

```javascript
exports.processEscalationSMS = functions.https.onRequest(async (req, res) => {
  // Verify request comes from Cloud Tasks
  const incomingToken = req.header('X-CloudTasks-TaskName');
  if (!incomingToken) {
    return res.status(403).json({error: 'Unauthorized'});
  }
  
  // ... rest of code
});
```

---

## 📈 Monitoring & Logging

### View Logs

```bash
# View all function logs
firebase functions:log

# View specific function
firebase functions:log --only processEscalationSMS

# Stream real-time logs
firebase functions:log --follow
```

### Check Cloud Tasks Queue

```bash
# List tasks in queue
gcloud tasks list --queue=alert-escalation-queue --location=us-central1

# Describe specific task
gcloud tasks describe TASK_NAME --queue=alert-escalation-queue --location=us-central1
```

### Firestore Monitoring

Check collections:
- `proctorial_alerts` - Alert status and escalation flags
- `sms_logs` - SMS send history
- `call_logs` - Call history

---

## 🎯 Key Takeaways

1. **Efficiency**: Tasks run **only when needed**, not every minute
2. **Cost Savings**: 99.3% reduction in invocations (2,880 → 20 per day)
3. **Cancellation**: Tasks auto-cancelled if proctor accepts alert
4. **Scalability**: Works for 1 alert/day or 1,000 alerts/day equally well
5. **No Waste**: 0 invocations when no alerts exist

---

## 📚 References

- [Cloud Tasks Documentation](https://cloud.google.com/tasks/docs)
- [Firebase Functions](https://firebase.google.com/docs/functions)
- [Twilio SMS API](https://www.twilio.com/docs/sms)
- [Twilio Voice API](https://www.twilio.com/docs/voice)

---

**Last Updated:** 2026-01-08  
**Version:** 2.0 (Optimized)
