import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../data/models/alert_model.dart';
import '../../../data/services/alert_service.dart';
import '../../../core/services/sms_escalation_service.dart';
import '../../../core/services/call_escalation_service.dart';

class AlertController extends ChangeNotifier {
  static final AlertController instance = AlertController._internal();
  AlertController._internal();

  final List<AlertModel> _alerts = [];
  final List<AlertNotification> _notifications = [];

  int _unreadNotificationCount = 0;
  String? _authToken; // Store auth token for API calls
  StreamSubscription<QuerySnapshot>? _alertsSubscription; // Real-time listener

  List<AlertModel> get alerts => _alerts;
  List<AlertNotification> get notifications => _notifications;
  int get unreadNotificationCount => _unreadNotificationCount;

  /// Set authentication token for API calls
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Initialize real-time listener for alerts
  void initializeRealtimeListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ User not authenticated - cannot initialize real-time listener');
      return;
    }

    // Cancel previous subscription if exists (for new login after logout)
    _alertsSubscription?.cancel();

    // Clear previous user's data before loading new user's data
    _alerts.clear();
    _notifications.clear();
    _unreadNotificationCount = 0;

    // Load persisted notifications from Firestore
    loadNotificationsFromStorage();

    // Listen to changes in user's alerts collection
    _alertsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            print(
              '📦 Alert snapshot received with ${snapshot.docs.length} documents',
            );

            // Track old statuses to detect changes
            final oldStatuses = Map.fromEntries(
              _alerts.map((alert) => MapEntry(alert.id, alert.status)),
            );

            _alerts.clear();
            for (var doc in snapshot.docs) {
              final alert = AlertModel.fromJson(doc.data());
              _alerts.add(alert);
              print(
                '📋 Alert loaded: ${alert.id} (status: ${alert.status.name})',
              );

              // Check if status changed from pending to accepted/rejected
              final oldStatus = oldStatuses[alert.id];
              if (oldStatus == AlertStatus.pending &&
                  (alert.status == AlertStatus.accepted ||
                      alert.status == AlertStatus.rejected)) {
                print(
                  '🎯 Alert ${alert.id} status changed to ${alert.status.name} - cancelling SMS and Call escalations',
                );
                SmsEscalationService.instance.cancelEscalation(alert.id);
                CallEscalationService.instance.cancelEscalation(alert.id);
              }
              // Also cancel if alert is already accepted/rejected on first load
              else if (oldStatus == null &&
                  (alert.status == AlertStatus.accepted ||
                      alert.status == AlertStatus.rejected)) {
                print(
                  '🎯 Alert ${alert.id} already ${alert.status.name} on load - cancelling SMS and Call escalations',
                );
                SmsEscalationService.instance.cancelEscalation(alert.id);
                CallEscalationService.instance.cancelEscalation(alert.id);
              }
            }

            print(
              '✅ Real-time alerts updated: ${_alerts.length} alerts loaded',
            );
            notifyListeners();
          },
          onError: (e) {
            print('❌ Error listening to alerts: $e');
          },
        );

    // No longer listen to Firestore notifications - only show "alert sent" notifications
    print('✅ Alert listener initialized (notifications disabled)');
  }

  /// Clear all notifications from Firestore
  Future<void> clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🗑️ Clearing all notifications...');

      final notificationDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      // Delete all notifications
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notificationDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear local notifications
      _notifications.clear();
      _unreadNotificationCount = 0;

      print(
        '✅ All notifications cleared: ${notificationDocs.docs.length} deleted',
      );
      notifyListeners();
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Cleanup listener when user logs out (but keep data for when they log in again)
  void logout() {
    _alertsSubscription?.cancel();
    // Don't clear data - keep it so user sees notifications when they log in again
    print('✅ AlertController listener cancelled for logout. Data preserved.');
  }

  /// Dispose real-time listener
  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  /// Create and send a new SOS alert
  /// This sends the alert to both local storage and backend
  Future<void> sendAlert({
    required String studentId,
    required String studentName,
    required String studentPhone,
    required String studentEmail,
    required double latitude,
    required double longitude,
    required String location,
    String? department,
    String? session,
    String? pulseBuilding,
    String? pulseFloor,
    String? pulseRoom,
    String? pulseMessage,
  }) async {
    try {
      final alert = AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: studentId,
        studentName: studentName,
        studentPhone: studentPhone,
        studentEmail: studentEmail,
        latitude: latitude,
        longitude: longitude,
        location: location,
        department: department,
        session: session,
        timestamp: DateTime.now(),
        status: AlertStatus.pending,
        pulseBuilding: pulseBuilding,
        pulseFloor: pulseFloor,
        pulseRoom: pulseRoom,
        pulseMessage: pulseMessage,
      );

      _alerts.add(alert);

      // Save to local storage
      await _saveAlertToStorage(alert);

      // Schedule SMS escalation after 60 seconds
      SmsEscalationService.instance.scheduleEscalation(alert.id);

      // Create a "sent successfully" notification for the student (local only, not saved to Firestore)
      _addNotification(
        alertId: alert.id,
        status: AlertStatus.pending,
        respondedByName: 'SafeLink System',
        saveToFirestore: false, // Don't save to Firestore to avoid duplicates
      );

      // Send to backend if auth token is available
      if (_authToken != null) {
        final success = await AlertService.instance.sendSosAlert(
          alert: alert,
          authToken: _authToken!,
        );
        if (!success) {
          print(
            '⚠️ Alert saved locally but failed to send to backend. Will retry when connection is available.',
          );
        }
      } else {
        print(
          '⚠️ Auth token not set. Alert saved locally but not sent to backend.',
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error sending alert: $e');
    }
  }

  /// Update alert status when proctor/security responds
  Future<void> updateAlertStatus({
    required String alertId,
    required AlertStatus status,
    required String respondedByName,
  }) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        final updatedAlert = _alerts[index].copyWith(
          status: status,
          respondedByName: respondedByName,
          respondedAt: DateTime.now(),
        );

        _alerts[index] = updatedAlert;

        // Cancel SMS and Call escalations if alert is accepted or rejected
        if (status == AlertStatus.accepted || status == AlertStatus.rejected) {
          SmsEscalationService.instance.cancelEscalation(alertId);
          CallEscalationService.instance.cancelEscalation(alertId);
        }

        // Add notification
        _addNotification(
          alertId: alertId,
          status: status,
          respondedByName: respondedByName,
        );

        // Save to local storage
        await _saveAlertToStorage(updatedAlert);

        notifyListeners();
      }
    } catch (e) {
      print('Error updating alert status: $e');
    }
  }

  /// Forward alert to security body (called by proctorial body)
  Future<void> forwardAlertToSecurity({required String alertId}) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        final updatedAlert = _alerts[index].copyWith(
          forwardedTo: 'security',
          forwardedAt: DateTime.now(),
        );

        _alerts[index] = updatedAlert;

        // Save to local storage
        await _saveAlertToStorage(updatedAlert);

        notifyListeners();
      }
    } catch (e) {
      print('Error forwarding alert: $e');
    }
  }

  /// Get alerts forwarded to security body
  List<AlertModel> getForwardedAlerts() {
    return _alerts.where((a) => a.forwardedTo == 'security').toList();
  }

  /// Get alerts for proctorial body (not forwarded yet)
  List<AlertModel> getProctorialAlerts() {
    return _alerts
        .where((a) => a.forwardedTo == null || a.forwardedTo == 'proctorial')
        .toList();
  }

  /// Add a notification to the list
  void _addNotification({
    required String alertId,
    required AlertStatus status,
    required String respondedByName,
    bool saveToFirestore =
        true, // Only save proctor responses, not "alert sent"
  }) {
    final notification = AlertNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      alertId: alertId,
      status: status,
      respondedByName: respondedByName,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications.insert(0, notification);
    _unreadNotificationCount++;

    // Save notification to Firestore for persistence (only proctor responses)
    if (saveToFirestore) {
      _saveNotificationToFirestore(notification);
    }

    print('🔔 Notification created: ${notification.id}');
  }

  /// Save notification to Firestore
  Future<void> _saveNotificationToFirestore(
    AlertNotification notification,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notification.id)
          .set({
            'id': notification.id,
            'alertId': notification.alertId,
            'status': notification.status.name,
            'respondedByName': notification.respondedByName,
            'timestamp': notification.timestamp,
            'isRead': notification.isRead,
          });

      print('✅ Notification saved to Firestore: ${notification.id}');
    } catch (e) {
      print('❌ Error saving notification to Firestore: $e');
    }
  }

  /// Mark notification as read
  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      if (!_notifications[index].isRead) {
        _unreadNotificationCount--;
      }

      // Update in Firestore
      _updateNotificationReadStatus(notificationId, true);

      notifyListeners();
    }
  }

  /// Update notification read status in Firestore
  Future<void> _updateNotificationReadStatus(
    String notificationId,
    bool isRead,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': isRead});
    } catch (e) {
      print('❌ Error updating notification read status: $e');
    }
  }

  /// Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification = notification.copyWith(isRead: true);
      }
    }
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  /// Get alert by ID
  AlertModel? getAlertById(String alertId) {
    try {
      return _alerts.firstWhere((a) => a.id == alertId);
    } catch (e) {
      return null;
    }
  }

  /// Get pending alerts
  List<AlertModel> getPendingAlerts() {
    return _alerts.where((a) => a.status == AlertStatus.pending).toList();
  }

  /// Get resolved alerts
  List<AlertModel> getResolvedAlerts() {
    return _alerts.where((a) => a.status != AlertStatus.pending).toList();
  }

  /// Clear old notifications (older than 7 days)
  void clearOldNotifications() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    _notifications.removeWhere((n) => n.timestamp.isBefore(sevenDaysAgo));
    notifyListeners();
  }

  /// Save alert to Firestore and local storage
  Future<void> _saveAlertToStorage(AlertModel alert) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated - alert not saved to Firebase');
        return;
      }

      // Save to Firestore under user's alerts collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alerts')
          .doc(alert.id)
          .set(alert.toJson());

      print('✅ Alert saved to Firebase: ${alert.id}');
      print('   Location: /users/${user.uid}/alerts/${alert.id}');

      // ALSO save to proctorial_alerts collection for dashboard
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alert.id)
          .set({
            ...alert.toJson(),
            'receivedAt': FieldValue.serverTimestamp(),
            'notificationsSent': false,
            'userId': user.uid, // Track which user sent this
          });

      print('✅ Alert also saved to proctorial_alerts collection');
      print('   Proctorial dashboard will now show this alert!');
    } catch (e) {
      print('❌ Error saving alert to Firebase: $e');
    }
  }

  /// Load alerts from Firestore
  Future<void> loadAlertsFromStorage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ User not authenticated - alerts not loaded from Firebase');
        return;
      }

      final alertDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .get();

      _alerts.clear();
      for (var doc in alertDocs.docs) {
        final alert = AlertModel.fromJson(doc.data());
        _alerts.add(alert);
      }

      print('✅ Loaded ${_alerts.length} alerts from Firebase');
      notifyListeners();
    } catch (e) {
      print('❌ Error loading alerts from Firebase: $e');
    }
  }

  /// Load notifications from Firestore
  Future<void> loadNotificationsFromStorage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          '❌ User not authenticated - notifications not loaded from Firebase',
        );
        return;
      }

      final notificationDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      _notifications.clear();
      _unreadNotificationCount = 0;

      for (var doc in notificationDocs.docs) {
        final data = doc.data();
        final notification = AlertNotification(
          id: data['id'] as String,
          alertId: data['alertId'] as String,
          status: AlertStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => AlertStatus.pending,
          ),
          respondedByName: data['respondedByName'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isRead: data['isRead'] as bool? ?? false,
        );

        _notifications.add(notification);
        if (!notification.isRead) {
          _unreadNotificationCount++;
        }
      }

      print(
        '✅ Loaded ${_notifications.length} notifications from Firebase (${_unreadNotificationCount} unread)',
      );
      notifyListeners();
    } catch (e) {
      print('❌ Error loading notifications from Firebase: $e');
    }
  }
}

/// Model for alert notifications
class AlertNotification {
  final String id;
  final String alertId;
  final AlertStatus status;
  final String respondedByName;
  final DateTime timestamp;
  bool isRead;

  AlertNotification({
    required this.id,
    required this.alertId,
    required this.status,
    required this.respondedByName,
    required this.timestamp,
    required this.isRead,
  });

  String getMessage() {
    final action = status == AlertStatus.accepted ? 'accepted' : 'rejected';
    return 'Your alert has been $action by $respondedByName';
  }

  AlertNotification copyWith({
    String? id,
    String? alertId,
    AlertStatus? status,
    String? respondedByName,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AlertNotification(
      id: id ?? this.id,
      alertId: alertId ?? this.alertId,
      status: status ?? this.status,
      respondedByName: respondedByName ?? this.respondedByName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
