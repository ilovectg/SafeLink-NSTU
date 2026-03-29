const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sgMail = require('@sendgrid/mail');
const {CloudTasksClient} = require('@google-cloud/tasks');

// Initialize admin SDK
admin.initializeApp();

// Get Firestore reference
const db = admin.firestore();

// Initialize Cloud Tasks client
const tasksClient = new CloudTasksClient();
const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'safe-93f85';
const functionLocation = 'us-central1'; // Where Cloud Functions are deployed
const taskLocation = 'asia-south1'; // Closest to Bangladesh (where tasks will run from)
const queue = 'alert-escalation-queue';

// SendGrid API key is expected in environment variable SENDGRID_API_KEY
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || functions.config().sendgrid?.api_key;
const SENDGRID_FROM = process.env.SENDGRID_FROM || functions.config().sendgrid?.from;

if (!SENDGRID_API_KEY) {
  console.warn('SENDGRID_API_KEY not set. Email sending will fail until this is configured.');
} else {
  sgMail.setApiKey(SENDGRID_API_KEY);
}

// Twilio Configuration (must be set via environment variables)
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || functions.config().twilio?.account_sid;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || functions.config().twilio?.auth_token;
const TWILIO_MESSAGING_SERVICE_SID = process.env.TWILIO_MESSAGING_SERVICE_SID || functions.config().twilio?.messaging_service_sid;

let twilioClient = null;
if (TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN) {
  twilioClient = require('twilio')(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
  console.log('✅ Twilio client initialized');
} else {
  console.warn('⚠️ Twilio credentials not set. SMS sending will be disabled.');
}

/**
 * Helper: Schedule Cloud Task for delayed execution
 * This creates a task that will run at a specific time in the future
 */
async function scheduleEscalationTask(alertId, delaySeconds, taskType) {
  try {
    const queuePath = tasksClient.queuePath(project, taskLocation, queue);
    const functionUrl = `https://${functionLocation}-${project}.cloudfunctions.net/${taskType}`;
    
    const task = {
      httpRequest: {
        httpMethod: 'POST',
        url: functionUrl,
        headers: {'Content-Type': 'application/json'},
        body: Buffer.from(JSON.stringify({alertId})).toString('base64'),
      },
      scheduleTime: {
        seconds: Math.floor(Date.now() / 1000) + delaySeconds,
      },
    };
    
    const [response] = await tasksClient.createTask({parent: queuePath, task});
    console.log(`✅ Scheduled ${taskType} task: ${response.name}`);
    return response.name;
  } catch (error) {
    console.error(`❌ Failed to schedule ${taskType} task:`, error.message);
    return null;
  }
}

// Configurable: how many OTPs allowed per email in a short window
const OTP_RATE_LIMIT_MAX = 5; // max OTPs
const OTP_RATE_LIMIT_WINDOW_MINUTES = 10; // minutes

// Callable function to request OTPs (safer than allowing direct client writes)
exports.requestOtp = functions.https.onCall(async (data, context) => {
  const email = (data.email || '').toString().trim().toLowerCase();
  const purpose = (data.purpose || 'signup').toString();

  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required');
  }

  // Enforce student domain for signup purpose
  if (purpose === 'signup' && !email.endsWith('@student.nstu.edu.bd')) {
    throw new functions.https.HttpsError('failed-precondition', 'Email must be a student institutional email (@student.nstu.edu.bd)');
  }

  // Rate limiting: check how many OTPs for this email in the time window
  const since = new Date(Date.now() - OTP_RATE_LIMIT_WINDOW_MINUTES * 60 * 1000);
  const recentQ = await admin.firestore().collection('email_otps')
    .where('email', '==', email)
    .where('purpose', '==', purpose)
    .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(since))
    .get();

  if (recentQ.size > OTP_RATE_LIMIT_MAX) {
    // Rate-limited
    return { ok: false, error: 'rate_limited' };
  }

  // Create OTP and optionally send immediately
  const code = (Math.floor(100000 + Math.random() * 900000)).toString();
  const now = new Date();
  const docRef = await admin.firestore().collection('email_otps').add({
    email,
    code,
    purpose,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(new Date(now.getTime() + 10 * 60 * 1000)),
  });

  // If sendgrid is not configured we will queue and return code in dev; otherwise attempt to send
  if (!SENDGRID_API_KEY || !SENDGRID_FROM) {
    await docRef.update({ sent: false, queued: true, queuedAt: admin.firestore.FieldValue.serverTimestamp() });
    return { ok: true, dev_code: code };
  }

  // Compose and send email
  try {
    const subject = `Your SafeLink NSTU verification code`;
    const text = `Your verification code is ${code}. It will expire in 10 minutes.`;
    const html = `<p>Your verification code is <strong>${code}</strong>.</p><p>It will expire in 10 minutes.</p>`;

    const msg = {
      to: email,
      from: SENDGRID_FROM,
      subject,
      text,
      html,
    };

    await sgMail.send(msg);
    await docRef.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    return { ok: true };
  } catch (err) {
    console.error('requestOtp send error', err);
    await docRef.update({ sendError: err.toString(), sendErrorAt: admin.firestore.FieldValue.serverTimestamp() });
    return { ok: false, error: 'send_failed' };
  }
});


exports.sendSignupOtpEmail = functions.firestore
  .document('email_otps/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return null;

    try {
      const email = (data.email || '').toString().trim().toLowerCase();
      const code = (data.code || '').toString().trim();
      const purpose = data.purpose || 'signup';

      if (!email || !code) {
        console.log('Invalid OTP document, missing email or code', context.params.docId);
        return null;
      }

      // If already marked sent, skip
      if (data.sent === true) {
        console.log('OTP already sent, skipping', context.params.docId);
        return null;
      }

      // Rate limiting: check how many OTPs for this email in the time window
      const since = new Date(Date.now() - OTP_RATE_LIMIT_WINDOW_MINUTES * 60 * 1000);
      const recentQ = await admin.firestore().collection('email_otps')
        .where('email', '==', email)
        .where('purpose', '==', purpose)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(since))
        .get();

      if (recentQ.size > OTP_RATE_LIMIT_MAX) {
        console.warn(`Rate limit reached for ${email}. Count=${recentQ.size}`);
        await snap.ref.update({ rateLimited: true });
        return null;
      }

      // Compose simple email
      const subject = `Your SafeLink NSTU verification code`;
      const text = `Your verification code is ${code}. It will expire in 10 minutes.`;
      const html = `<p>Your verification code is <strong>${code}</strong>.</p><p>It will expire in 10 minutes.</p>`;

      if (!SENDGRID_API_KEY || !SENDGRID_FROM) {
        console.warn('SendGrid not configured, skipping actual send (dev mode).');
        // Mark sent=false but attach debug hints
        await snap.ref.update({ sent: false, queued: true, queuedAt: admin.firestore.FieldValue.serverTimestamp() });
        return null;
      }

      const msg = {
        to: email,
        from: SENDGRID_FROM,
        subject,
        text,
        html,
      };

      await sgMail.send(msg);
      console.log('OTP email sent to', email);

      // Mark document as sent
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
      return null;
    } catch (err) {
      console.error('Error in sendSignupOtpEmail:', err);
      try { await snap.ref.update({ sendError: err.toString(), sendErrorAt: admin.firestore.FieldValue.serverTimestamp() }); } catch (_) {}
      return null;
    }
  });

// ============================================================================
// SOS ALERT SYSTEM - PROCTORIAL BODY NOTIFICATIONS
// ============================================================================

/**
 * HTTP Endpoint: Receive SOS Alert from Student App
 * POST /api/v1/alerts/send
 */
exports.sendSosAlert = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Get alert data from request
    const alertData = req.body;

    console.log('🚨 SOS ALERT RECEIVED FROM STUDENT');
    console.log('Student ID:', alertData.studentId);
    console.log('Student Name:', alertData.studentName);
    console.log('Location:', alertData.location);
    console.log('GPS:', alertData.latitude, alertData.longitude);

    // Validate required fields
    if (!alertData.studentId || !alertData.studentName) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Save alert to global alerts collection for proctorial body
    const alertRef = await db.collection('proctorial_alerts').add({
      ...alertData,
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      notificationsSent: false,
      // Escalation tracking (FR14, FR15, FR16)
      smsEscalated: false,
      smsEscalatedAt: null,
      callEscalated: false,
      callEscalatedAt: null,
      acceptedBy: null,
      acceptedByName: null,
      acceptedAt: null,
    });

    console.log('✅ Alert saved to proctorial_alerts:', alertRef.id);

    // Schedule escalation tasks (OPTIMAL: Only runs when needed!)
    console.log('⏰ Scheduling escalation tasks...');
    const smsTaskName = await scheduleEscalationTask(alertRef.id, 60, 'processEscalationSMS'); // 1 minute
    const callTaskName = await scheduleEscalationTask(alertRef.id, 300, 'processEscalationCall'); // 5 minutes
    
    // Store task names so we can cancel them if alert is accepted
    await alertRef.update({
      smsEscalationTaskName: smsTaskName,
      callEscalationTaskName: callTaskName,
    });

    // Get all proctorial staff tokens for push notifications from users collection
    const proctorsSnapshot = await db.collection('users')
      .where('role', '==', 'proctorial')
      .get();

    const fcmTokens = [];
    proctorsSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.fcmToken) {
        fcmTokens.push(data.fcmToken);
        console.log(`  📱 Found FCM token for: ${data.email}`);
      }
    });

    console.log(`📊 Total proctorial staff found: ${proctorsSnapshot.size}, with FCM tokens: ${fcmTokens.length}`);

    // Send push notifications to all proctors
    if (fcmTokens.length > 0) {
      const message = {
        notification: {
          title: '🚨 EMERGENCY ALERT',
          body: `${alertData.studentName} (${alertData.studentId}) needs help at ${alertData.location}`,
        },
        data: {
          alertId: alertRef.id,
          studentId: alertData.studentId,
          studentName: alertData.studentName,
          latitude: String(alertData.latitude),
          longitude: String(alertData.longitude),
          type: 'sos_alert',
        },
        tokens: fcmTokens,
      };

      const response = await admin.messaging().sendMulticast(message);
      console.log(`✅ Notifications sent: ${response.successCount} successful, ${response.failureCount} failed`);

      // Update alert with notification status
      await alertRef.update({
        notificationsSent: true,
        notificationCount: response.successCount,
      });
    } else {
      console.log('⚠️ No proctorial staff FCM tokens found');
    }

    // Return success
    return res.status(200).json({
      success: true,
      alertId: alertRef.id,
      message: 'Alert received and proctorial body notified',
      notificationsSent: fcmTokens.length,
    });

  } catch (error) {
    console.error('❌ Error processing SOS alert:', error);
    return res.status(500).json({
      error: 'Internal server error',
      message: error.message,
    });
  }
});

/**
 * HTTP Endpoint: Accept Alert (Proctor Response)
 * POST /api/v1/alerts/:alertId/accept
 */
exports.acceptAlert = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  try {
    const alertId = req.query.alertId || req.body.alertId;
    const proctorName = req.body.proctorName || 'Proctor';
    const proctorId = req.body.proctorId;

    if (!alertId) {
      return res.status(400).json({ error: 'Alert ID required' });
    }

    // Update alert in proctorial_alerts
    const alertRef = db.collection('proctorial_alerts').doc(alertId);
    const alertDocSnapshot = await alertRef.get();
    
    if (!alertDocSnapshot.exists) {
      return res.status(404).json({ error: 'Alert not found' });
    }
    
    const alertData = alertDocSnapshot.data();
    
    // Cancel scheduled escalation tasks (Cloud Tasks)
    if (alertData.smsEscalationTaskName) {
      try {
        console.log(`🔴 Cancelling SMS escalation task: ${alertData.smsEscalationTaskName}`);
        await tasksClient.deleteTask({name: alertData.smsEscalationTaskName});
        console.log('✅ SMS escalation task cancelled');
      } catch (cancelError) {
        // Task may have already executed or not exist
        console.log(`⚠️ Could not cancel SMS task: ${cancelError.message}`);
      }
    }
    
    if (alertData.callEscalationTaskName) {
      try {
        console.log(`🔴 Cancelling call escalation task: ${alertData.callEscalationTaskName}`);
        await tasksClient.deleteTask({name: alertData.callEscalationTaskName});
        console.log('✅ Call escalation task cancelled');
      } catch (cancelError) {
        // Task may have already executed or not exist
        console.log(`⚠️ Could not cancel call task: ${cancelError.message}`);
      }
    }
    
    // Update alert status
    await alertRef.update({
      status: 'accepted',
      respondedByName: proctorName,
      respondedById: proctorId,
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      escalationsCancelled: true,
    });

    // Find student's alert in their personal collection and update it
    // alertData already retrieved earlier, reuse it

    if (alertData && alertData.studentId) {
      // Find user by studentId
      const userSnapshot = await db.collection('users')
        .where('studentId', '==', alertData.studentId)
        .limit(1)
        .get();

      if (!userSnapshot.empty) {
        const userId = userSnapshot.docs[0].id;
        
        // Update student's personal alert
        const studentAlertsSnapshot = await db.collection('users')
          .doc(userId)
          .collection('alerts')
          .where('id', '==', alertData.id)
          .limit(1)
          .get();

        if (!studentAlertsSnapshot.empty) {
          await studentAlertsSnapshot.docs[0].ref.update({
            status: 'accepted',
            respondedByName: proctorName,
            respondedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Send notification back to student
        const userData = userSnapshot.docs[0].data();
        if (userData.fcmToken) {
          await admin.messaging().send({
            notification: {
              title: '✅ Help is on the way!',
              body: `${proctorName} has accepted your emergency alert and is coming to help.`,
            },
            token: userData.fcmToken,
          });
        }
      }
    }

    console.log(`✅ Alert ${alertId} accepted by ${proctorName}`);

    return res.status(200).json({
      success: true,
      message: 'Alert accepted',
    });

  } catch (error) {
    console.error('❌ Error accepting alert:', error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * HTTP Endpoint: Reject Alert (Proctor Response)
 * POST /api/v1/alerts/:alertId/reject
 */
exports.rejectAlert = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  try {
    const alertId = req.query.alertId || req.body.alertId;
    const proctorName = req.body.proctorName || 'Proctor';
    const proctorId = req.body.proctorId;
    const reason = req.body.reason || 'No reason provided';

    if (!alertId) {
      return res.status(400).json({ error: 'Alert ID required' });
    }

    // Update alert in proctorial_alerts
    await db.collection('proctorial_alerts').doc(alertId).update({
      status: 'rejected',
      respondedByName: proctorName,
      respondedById: proctorId,
      respondedAt: admin.firestore.FieldValue.serverTimestamp(),
      rejectionReason: reason,
    });

    // Update student's personal alert
    const alertDoc = await db.collection('proctorial_alerts').doc(alertId).get();
    const alertData = alertDoc.data();

    if (alertData && alertData.studentId) {
      const userSnapshot = await db.collection('users')
        .where('studentId', '==', alertData.studentId)
        .limit(1)
        .get();

      if (!userSnapshot.empty) {
        const userId = userSnapshot.docs[0].id;
        
        const studentAlertsSnapshot = await db.collection('users')
          .doc(userId)
          .collection('alerts')
          .where('id', '==', alertData.id)
          .limit(1)
          .get();

        if (!studentAlertsSnapshot.empty) {
          await studentAlertsSnapshot.docs[0].ref.update({
            status: 'rejected',
            respondedByName: proctorName,
            respondedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Send notification to student
        const userData = userSnapshot.docs[0].data();
        if (userData.fcmToken) {
          await admin.messaging().send({
            notification: {
              title: 'Alert Status Update',
              body: `Your alert was reviewed by ${proctorName}. Reason: ${reason}`,
            },
            token: userData.fcmToken,
          });
        }
      }
    }

    console.log(`❌ Alert ${alertId} rejected by ${proctorName}`);

    return res.status(200).json({
      success: true,
      message: 'Alert rejected',
    });

  } catch (error) {
    console.error('❌ Error rejecting alert:', error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * HTTP Endpoint: Get All Pending Alerts (for Proctorial Dashboard)
 * GET /api/v1/alerts/pending
 */
exports.getPendingAlerts = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  try {
    const alertsSnapshot = await db.collection('proctorial_alerts')
      .where('status', '==', 'pending')
      .orderBy('receivedAt', 'desc')
      .limit(50)
      .get();

    const alerts = [];
    alertsSnapshot.forEach(doc => {
      alerts.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    return res.status(200).json({
      success: true,
      count: alerts.length,
      alerts: alerts,
    });

  } catch (error) {
    console.error('❌ Error fetching alerts:', error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * HTTP Endpoint: Get All Alerts (for Proctorial Dashboard)
 * GET /api/v1/alerts/all
 */
exports.getAllAlerts = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  try {
    const status = req.query.status; // optional filter
    let query = db.collection('proctorial_alerts').orderBy('receivedAt', 'desc').limit(100);

    if (status) {
      query = query.where('status', '==', status);
    }

    const alertsSnapshot = await query.get();

    const alerts = [];
    alertsSnapshot.forEach(doc => {
      alerts.push({
        id: doc.id,
        ...doc.data(),
      });
    });

    return res.status(200).json({
      success: true,
      count: alerts.length,
      alerts: alerts,
    });

  } catch (error) {
    console.error('❌ Error fetching alerts:', error);
    return res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// TWILIO SMS NOTIFICATION FUNCTION
// ============================================================================

/**
 * Send SMS notification via Twilio when shake alert is triggered
 * 
 * Callable function that sends SMS to guardians/emergency contacts
 * Called from Flutter app when shake is detected
 * 
 * @param {Object} data
 * @param {string} data.phoneNumber - Recipient phone number (must include country code, e.g., +8801322260557)
 * @param {string} data.studentName - Name of the student in emergency
 * @param {string} data.location - Location where alert was triggered
 * @param {string} data.alertType - Type of alert ('shake', 'button', etc.)
 */
exports.sendShakeAlertSMS = functions.https.onCall(async (data, context) => {
  try {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { phoneNumber, studentName, location, alertType = 'shake' } = data;

    if (!phoneNumber) {
      throw new functions.https.HttpsError('invalid-argument', 'Phone number is required');
    }

    // Validate phone number format (should start with +88 for Bangladesh)
    const cleanPhone = phoneNumber.toString().trim();
    if (!cleanPhone.startsWith('+')) {
      throw new functions.https.HttpsError('invalid-argument', 'Phone number must include country code (e.g., +8801...)');
    }

    // Check if Twilio is configured
    if (!twilioClient) {
      console.error('❌ Twilio not configured');
      return { success: false, error: 'SMS service not configured' };
    }

    // Construct SMS message
    const message = `🚨 EMERGENCY ALERT from SafeLink NSTU\n\n` +
                   `Student: ${studentName || 'Unknown'}\n` +
                   `Alert Type: ${alertType.toUpperCase()}\n` +
                   `Location: ${location || 'Unknown'}\n` +
                   `Time: ${new Date().toLocaleString()}\n\n` +
                   `This is an automated emergency alert. Please respond immediately.`;

    console.log(`📤 Sending SMS to ${cleanPhone}`);
    console.log(`Message: ${message}`);

    // Send SMS via Twilio
    const twilioResponse = await twilioClient.messages.create({
      body: message,
      messagingServiceSid: TWILIO_MESSAGING_SERVICE_SID,
      to: cleanPhone
    });

    console.log(`✅ SMS sent successfully. SID: ${twilioResponse.sid}`);

    // Log SMS in Firestore for audit trail
    await db.collection('sms_logs').add({
      userId: context.auth.uid,
      phoneNumber: cleanPhone,
      message: message,
      alertType: alertType,
      twilioSid: twilioResponse.sid,
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      messageSid: twilioResponse.sid,
      sentTo: cleanPhone
    };

  } catch (error) {
    console.error('❌ Error sending SMS:', error);
    
    // Log failed SMS attempt
    try {
      await db.collection('sms_logs').add({
        userId: context.auth?.uid || 'unknown',
        phoneNumber: data.phoneNumber,
        alertType: data.alertType || 'shake',
        status: 'failed',
        error: error.message,
        attemptedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (logError) {
      console.error('Failed to log SMS error:', logError);
    }

    throw new functions.https.HttpsError('internal', `SMS sending failed: ${error.message}`);
  }
});

// ============================================================================
// ALERT ESCALATION FUNCTIONS (FR14, FR15, FR16) - ON-DEMAND EXECUTION
// ============================================================================

/**
 * HTTP Function: Process SMS Escalation (FR14)
 * Triggered by Cloud Task exactly 1 minute after alert creation
 * Only runs if alert is still pending
 * 
 * OPTIMAL: Runs only when needed (not every minute!)
 */
exports.processEscalationSMS = functions.https.onRequest(async (req, res) => {
  console.log('📨 Processing SMS escalation task...');
  
  try {
    const {alertId} = req.body;
    
    if (!alertId) {
      console.error('❌ No alertId provided');
      return res.status(400).json({error: 'Missing alertId'});
    }
    
    // Get alert document
    const alertDoc = await db.collection('proctorial_alerts').doc(alertId).get();
    
    if (!alertDoc.exists) {
      console.error(`❌ Alert ${alertId} not found`);
      return res.status(404).json({error: 'Alert not found'});
    }
    
    const alert = alertDoc.data();
    
    // Check if alert is still pending (not accepted/rejected)
    if (alert.status !== 'pending') {
      console.log(`✅ Alert ${alertId} already ${alert.status} - skipping SMS escalation`);
      return res.status(200).json({message: `Alert already ${alert.status}`, skipped: true});
    }
    
    // Check if already SMS escalated
    if (alert.smsEscalated) {
      console.log(`✅ Alert ${alertId} already SMS escalated - skipping`);
      return res.status(200).json({message: 'Already escalated', skipped: true});
    }
    
    console.log(`📤 Alert ${alertId} still pending - sending SMS escalation`);
    console.log(`   Student: ${alert.studentName} (${alert.studentId})`);
    console.log(`   Location: ${alert.location}`);
    
    // Get ALL proctors' phone numbers
    const proctorsSnapshot = await db.collection('users')
      .where('role', '==', 'proctorial')
      .get();
    
    const proctorPhones = [];
    proctorsSnapshot.forEach(doc => {
      const phone = doc.data().phone;
      if (phone) {
        proctorPhones.push(phone);
      }
    });
    
    if (proctorPhones.length === 0) {
      console.log('⚠️ No proctor phone numbers found');
      await alertDoc.ref.update({
        smsEscalated: true,
        smsEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
        smsEscalationError: 'No proctor phones found'
      });
      return res.status(200).json({message: 'No proctor phones', success: false});
    }
    
    console.log(`📱 Found ${proctorPhones.length} proctor phone(s)`);
    
    // Check if Twilio is configured
    if (!twilioClient) {
      console.error('❌ Twilio not configured');
      await alertDoc.ref.update({
        smsEscalated: true,
        smsEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
        smsEscalationError: 'Twilio not configured'
      });
      return res.status(200).json({message: 'Twilio not configured', success: false});
    }
    
    // Construct SMS message
    const smsMessage = `🚨 URGENT ALERT NOT RESPONDED\n\n` +
                      `Student: ${alert.studentName}\n` +
                      `ID: ${alert.studentId}\n` +
                      `Location: ${alert.location}\n` +
                      `Time: ${alert.receivedAt?.toDate().toLocaleString('en-US', {timeZone: 'Asia/Dhaka'})}\n\n` +
                      `Please open SafeLink NSTU app to respond.\n` +
                      `Alert ID: ${alertId}`;
    
    // Send SMS to ALL proctors
    let successCount = 0;
    let failureCount = 0;
    
    for (const phone of proctorPhones) {
      try {
        const twilioResponse = await twilioClient.messages.create({
          body: smsMessage,
          messagingServiceSid: TWILIO_MESSAGING_SERVICE_SID,
          to: phone
        });
        
        console.log(`   ✅ SMS sent to ${phone} (SID: ${twilioResponse.sid})`);
        successCount++;
        
        // Log SMS
        await db.collection('sms_logs').add({
          alertId: alertId,
          phoneNumber: phone,
          message: smsMessage,
          twilioSid: twilioResponse.sid,
          type: 'escalation_1min',
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
      } catch (smsError) {
        console.error(`   ❌ Failed to send SMS to ${phone}:`, smsError.message);
        failureCount++;
        
        await db.collection('sms_logs').add({
          alertId: alertId,
          phoneNumber: phone,
          message: smsMessage,
          type: 'escalation_1min',
          status: 'failed',
          error: smsError.message,
          attemptedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
    
    // Update alert
    await alertDoc.ref.update({
      smsEscalated: true,
      smsEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
      smsEscalationSuccess: successCount,
      smsEscalationFailure: failureCount,
    });
    
    console.log(`✅ SMS escalation complete: ${successCount}/${proctorPhones.length} sent`);
    return res.status(200).json({
      success: true,
      alertId,
      smsSent: successCount,
      smsFailed: failureCount
    });
    
  } catch (error) {
    console.error('❌ Error in SMS escalation:', error);
    return res.status(500).json({error: error.message});
  }
});

/**
 * HTTP Function: Process Call Escalation (FR15, FR16)
 * Triggered by Cloud Task exactly 5 minutes after alert creation
 * Only runs if alert is still pending
 * 
 * OPTIMAL: Runs only when needed (not every minute!)
 */
exports.processEscalationCall = functions.https.onRequest(async (req, res) => {
  console.log('📞 Processing call escalation task...');
  
  try {
    const {alertId} = req.body;
    
    if (!alertId) {
      console.error('❌ No alertId provided');
      return res.status(400).json({error: 'Missing alertId'});
    }
    
    // Get alert document
    const alertDoc = await db.collection('proctorial_alerts').doc(alertId).get();
    
    if (!alertDoc.exists) {
      console.error(`❌ Alert ${alertId} not found`);
      return res.status(404).json({error: 'Alert not found'});
    }
    
    const alert = alertDoc.data();
    
    // Check if alert is still pending
    if (alert.status !== 'pending') {
      console.log(`✅ Alert ${alertId} already ${alert.status} - skipping call escalation`);
      return res.status(200).json({message: `Alert already ${alert.status}`, skipped: true});
    }
    
    // Check if already call escalated
    if (alert.callEscalated) {
      console.log(`✅ Alert ${alertId} already call escalated - skipping`);
      return res.status(200).json({message: 'Already escalated', skipped: true});
    }
    
    console.log(`📞 Alert ${alertId} still pending after 5 minutes - initiating call`);
    console.log(`   Student: ${alert.studentName} (${alert.studentId})`);
    console.log(`   Location: ${alert.location}`);
    
    // Check if Twilio is configured
    if (!twilioClient) {
      console.error('❌ Twilio not configured');
      await alertDoc.ref.update({
        status: 'escalated',
        callEscalated: true,
        callEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
        callEscalationError: 'Twilio not configured'
      });
      return res.status(200).json({message: 'Twilio not configured', success: false});
    }
    
    // Emergency hotline number
    const hotlineNumber = process.env.EMERGENCY_HOTLINE || functions.config().hotline?.number || '+8801322260557';
    console.log(`📞 Calling hotline: ${hotlineNumber}`);
    
    // Construct voice message
    const voiceMessage = `Emergency alert from SafeLink NSTU. ` +
                        `Student ${alert.studentName}, ` +
                        `ID ${alert.studentId}, ` +
                        `needs help at ${alert.location}. ` +
                        `GPS coordinates: latitude ${alert.latitude}, longitude ${alert.longitude}. ` +
                        `This alert has not been responded to for 5 minutes. ` +
                        `Alert ID: ${alertId}. ` +
                        `Please respond immediately.`;
    
    try {
      // Make call via Twilio
      const twilioResponse = await twilioClient.calls.create({
        twiml: `<Response><Say voice="alice">${voiceMessage}</Say><Pause length="2"/><Say voice="alice">Repeating message.</Say><Say voice="alice">${voiceMessage}</Say></Response>`,
        to: hotlineNumber,
        from: TWILIO_MESSAGING_SERVICE_SID
      });
      
      console.log(`   ✅ Call initiated (SID: ${twilioResponse.sid})`);
      
      // Log call
      await db.collection('call_logs').add({
        alertId: alertId,
        phoneNumber: hotlineNumber,
        message: voiceMessage,
        twilioSid: twilioResponse.sid,
        type: 'escalation_5min',
        status: 'initiated',
        initiatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Update alert status to 'escalated'
      await alertDoc.ref.update({
        status: 'escalated',
        callEscalated: true,
        callEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
        callSid: twilioResponse.sid,
      });
      
      console.log(`✅ Call escalation complete for alert ${alertId}`);
      return res.status(200).json({
        success: true,
        alertId,
        callSid: twilioResponse.sid
      });
      
    } catch (callError) {
      console.error(`   ❌ Failed to initiate call:`, callError.message);
      
      await db.collection('call_logs').add({
        alertId: alertId,
        phoneNumber: hotlineNumber,
        message: voiceMessage,
        type: 'escalation_5min',
        status: 'failed',
        error: callError.message,
        attemptedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      await alertDoc.ref.update({
        status: 'escalated',
        callEscalated: true,
        callEscalatedAt: admin.firestore.FieldValue.serverTimestamp(),
        callEscalationError: callError.message,
      });
      
      return res.status(200).json({
        success: false,
        alertId,
        error: callError.message
      });
    }
    
  } catch (error) {
    console.error('❌ Error in call escalation:', error);
    return res.status(500).json({error: error.message});
  }
});
