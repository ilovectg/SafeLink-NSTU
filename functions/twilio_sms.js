// ============================================================================
// TWILIO SMS NOTIFICATION FUNCTION
// ============================================================================

const functions = require('firebase-functions');
const admin = require('firebase-admin');

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
    const db = admin.firestore();
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
      const db = admin.firestore();
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
