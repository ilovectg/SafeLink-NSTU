// Backend Implementation Example - Node.js/Express

/**
 * Example backend implementation for receiving SOS alerts
 * This shows how to handle the alert and route it to proctorial staff
 */

// ============================================
// ROUTE: POST /api/v1/alerts/send
// ============================================

app.post('/api/v1/alerts/send', authenticateUser, async (req, res) => {
  try {
    const alertData = req.body;

    // Validate required fields
    const requiredFields = [
      'studentId', 'studentName', 'studentPhone', 'studentEmail',
      'department', 'session', 'latitude', 'longitude', 'location'
    ];

    for (const field of requiredFields) {
      if (!alertData[field]) {
        return res.status(400).json({
          success: false,
          message: `Missing required field: ${field}`
        });
      }
    }

    // Create alert in database
    const alertId = `alert_${Date.now()}`;
    const alert = {
      id: alertId,
      studentId: alertData.studentId,
      studentName: alertData.studentName,
      studentPhone: alertData.studentPhone,
      studentEmail: alertData.studentEmail,
      department: alertData.department,
      session: alertData.session,
      latitude: alertData.latitude,
      longitude: alertData.longitude,
      location: alertData.location,
      status: 'pending',
      createdAt: new Date(),
      responders: []
    };

    // Save to database
    await AlertModel.create(alert);

    // Send push notifications to all proctorial staff
    const procotorialStaff = await StaffModel.find({ 
      role: 'proctor' 
    });

    for (const staff of procotorialStaff) {
      // Send Firebase Cloud Messaging (FCM) notification
      await sendFCMNotification({
        to: staff.fcmToken,
        title: '🚨 EMERGENCY ALERT',
        body: `${alertData.studentName} (${alertData.studentId}) from ${alertData.department} needs help!`,
        data: {
          alertId: alertId,
          latitude: alertData.latitude,
          longitude: alertData.longitude,
          studentId: alertData.studentId
        }
      });

      // Send email notification
      await sendEmail({
        to: staff.email,
        subject: `URGENT: SOS Alert from ${alertData.studentName}`,
        template: 'sos-alert',
        data: alert
      });
    }

    // Return success response
    return res.status(201).json({
      success: true,
      alertId: alertId,
      message: 'Alert received. Help is on the way.',
      createdAt: new Date()
    });

  } catch (error) {
    console.error('Error sending alert:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to process alert'
    });
  }
});


// ============================================
// ROUTE: POST /api/v1/alerts/:alertId/accept
// ============================================

app.post('/api/v1/alerts/:alertId/accept', authenticateUser, async (req, res) => {
  try {
    const { alertId } = req.params;
    const { acceptedBy } = req.body;

    // Update alert status
    const alert = await AlertModel.findByIdAndUpdate(
      alertId,
      {
        status: 'accepted',
        'responders': {
          acceptedBy: acceptedBy,
          acceptedAt: new Date()
        }
      },
      { new: true }
    );

    // Send notification to student
    const student = await StudentModel.findById(alert.studentId);
    await sendFCMNotification({
      to: student.fcmToken,
      title: '✅ Your alert was accepted',
      body: `${acceptedBy} has accepted your emergency alert`,
      data: {
        alertId: alertId,
        status: 'accepted'
      }
    });

    return res.json({
      success: true,
      message: 'Alert accepted',
      alert: alert
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to accept alert'
    });
  }
});


// ============================================
// ROUTE: POST /api/v1/alerts/:alertId/reject
// ============================================

app.post('/api/v1/alerts/:alertId/reject', authenticateUser, async (req, res) => {
  try {
    const { alertId } = req.params;
    const { rejectedBy, reason } = req.body;

    // Update alert status
    const alert = await AlertModel.findByIdAndUpdate(
      alertId,
      {
        status: 'rejected',
        'responders': {
          rejectedBy: rejectedBy,
          rejectedAt: new Date(),
          reason: reason
        }
      },
      { new: true }
    );

    // Send notification to student
    const student = await StudentModel.findById(alert.studentId);
    await sendFCMNotification({
      to: student.fcmToken,
      title: '⚠️ Your alert was rejected',
      body: `${rejectedBy} rejected your alert. Reason: ${reason}`,
      data: {
        alertId: alertId,
        status: 'rejected'
      }
    });

    return res.json({
      success: true,
      message: 'Alert rejected',
      alert: alert
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to reject alert'
    });
  }
});


// ============================================
// ROUTE: POST /api/v1/alerts/:alertId/forward-to-security
// ============================================

app.post('/api/v1/alerts/:alertId/forward-to-security', authenticateUser, async (req, res) => {
  try {
    const { alertId } = req.params;
    const { forwardedBy } = req.body;

    // Update alert
    const alert = await AlertModel.findByIdAndUpdate(
      alertId,
      {
        forwardedTo: 'security',
        forwardedAt: new Date(),
        forwardedBy: forwardedBy
      },
      { new: true }
    );

    // Send notifications to security team
    const securityTeam = await StaffModel.find({ role: 'security' });

    for (const member of securityTeam) {
      await sendFCMNotification({
        to: member.fcmToken,
        title: '🚨 ALERT FORWARDED FROM PROCTOR',
        body: `${alert.studentName} (${alert.studentId}) - ${alert.location}`,
        data: {
          alertId: alertId,
          forwardedBy: forwardedBy
        }
      });
    }

    return res.json({
      success: true,
      message: 'Alert forwarded to security',
      alert: alert
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to forward alert'
    });
  }
});


// ============================================
// ROUTE: GET /api/v1/alerts?studentId={id}
// ============================================

app.get('/api/v1/alerts', authenticateUser, async (req, res) => {
  try {
    const { studentId } = req.query;

    const alerts = await AlertModel.find({ studentId });

    return res.json({
      success: true,
      alerts: alerts
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch alerts'
    });
  }
});


// ============================================
// DATABASE SCHEMA (MongoDB)
// ============================================

const alertSchema = new mongoose.Schema({
  id: String,
  studentId: String,
  studentName: String,
  studentPhone: String,
  studentEmail: String,
  department: String,
  session: String,
  latitude: Number,
  longitude: Number,
  location: String,
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending'
  },
  responders: {
    acceptedBy: String,
    acceptedAt: Date,
    rejectedBy: String,
    rejectedAt: Date,
    reason: String
  },
  forwardedTo: String,
  forwardedAt: Date,
  forwardedBy: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const AlertModel = mongoose.model('Alert', alertSchema);


// ============================================
// PUSH NOTIFICATION HELPER
// ============================================

async function sendFCMNotification(payload) {
  const message = {
    notification: {
      title: payload.title,
      body: payload.body
    },
    data: payload.data,
    token: payload.to
  };

  try {
    await admin.messaging().send(message);
    console.log('✓ Notification sent:', payload.title);
  } catch (error) {
    console.error('✗ Failed to send notification:', error);
  }
}


// ============================================
// INITIALIZATION
// ============================================

// Initialize Firebase Admin SDK
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✓ Backend SOS Alert System Initialized');
