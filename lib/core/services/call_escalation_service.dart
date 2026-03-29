import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safelink_n/core/constants/app_constants.dart';
import '../utils/native_call.dart';
import 'volume_button_sos_service.dart';

/// Service to schedule call escalation after 5 minutes for alerts that had SMS sent
class CallEscalationService {
  static final CallEscalationService _instance =
      CallEscalationService._internal();
  CallEscalationService._internal();
  static CallEscalationService get instance => _instance;

  final Map<String, Timer> _activeTimers = {}; // One timer per alert
  BuildContext? _context; // For showing countdown dialog

  /// Set context for showing countdown dialogs
  void setContext(BuildContext context) {
    _context = context;
    print('✅ Call Escalation service context set');
  }

  /// Clear context when screen disposed
  void clearContext() {
    _context = null;
    print('✅ Call Escalation service context cleared');
  }

  /// Schedule call escalation for a specific alert (after SMS has been sent)
  Future<void> scheduleEscalation(String alertId) async {
    print('📞 scheduleEscalation called for alert $alertId');

    // Check if call has already been escalated
    try {
      final alertDoc = await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alertId)
          .get();

      if (alertDoc.exists) {
        final alertData = alertDoc.data()!;
        final bool callEscalated = alertData['callEscalated'] ?? false;

        if (callEscalated) {
          print('⏭️ Call already escalated for alert $alertId - skipping');
          return;
        }
      }
    } catch (e) {
      print('⚠️ Error checking call escalation status: $e');
      // Continue with scheduling if check fails
    }

    // Cancel existing timer if any (shouldn't happen, but just in case)
    _activeTimers[alertId]?.cancel();

    // DEVELOPMENT: 20 seconds for testing, 300 (5 minutes) for production
    const int escalationDelaySeconds = AppConstants.callDelaySeconds;

    print(
      '📞 Scheduled call escalation for alert $alertId (in $escalationDelaySeconds seconds)',
    );
    print('   Context available: ${_context != null}');
    print('   Context mounted: ${_context?.mounted}');

    // Start timer for this specific alert
    _activeTimers[alertId] = Timer(
      Duration(seconds: escalationDelaySeconds),
      () async {
        print(
          '📞 $escalationDelaySeconds seconds elapsed for alert $alertId - triggering call escalation',
        );
        print('   Context still available: ${_context != null}');
        print('   Context still mounted: ${_context?.mounted}');

        // Remove timer immediately when dialog appears (not after calls complete)
        _activeTimers.remove(alertId);
        print('✅ Timer stopped for alert $alertId');

        await _triggerCallEscalation(alertId);
      },
    );
  }

  /// Cancel escalation for a specific alert (when accepted/resolved)
  void cancelEscalation(String alertId) {
    final timer = _activeTimers[alertId];
    if (timer != null) {
      timer.cancel();
      _activeTimers.remove(alertId);
      print('🚫 Call escalation cancelled for alert $alertId');
    }
  }

  /// Cancel all active timers (when service stops)
  void cancelAllEscalations() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    print('🚫 All call escalations cancelled');
  }

  /// Trigger call escalation with countdown
  Future<void> _triggerCallEscalation(String alertId) async {
    print('🎯 _triggerCallEscalation called for alert $alertId');

    if (_context == null || !_context!.mounted) {
      print(
        '⚠️ No context available for countdown dialog - initiating calls directly',
      );
      await _initiateCallsToProctors(alertId);
      return;
    }

    print('✅ Showing call countdown dialog...');
    // Show countdown dialog
    await showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (dialogContext) => _CallCountdownDialog(
        alertId: alertId,
        onComplete: () async {
          print('📞 User confirmed or countdown finished - initiating calls');
          // Don't pop here - caller handles it
          await _initiateCallsToProctors(alertId);
        },
        onCancel: () {
          print('🚫 User cancelled call escalation');
          // onCancel is only called after pop, so don't pop again
        },
      ),
    );
  }

  /// Initiate calls to proctors
  Future<void> _initiateCallsToProctors(String alertId) async {
    print('📞 Starting call escalation for alert $alertId');

    // Pause volume button SOS to prevent false triggers during call
    VolumeButtonSosService.instance.pause();
    print('⏸️ Volume button SOS paused during call escalation');

    try {
      // Get alert details
      final alertDoc = await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alertId)
          .get();

      if (!alertDoc.exists) {
        print('⚠️ Alert $alertId not found');
        return;
      }

      final alertData = alertDoc.data()!;
      final studentName = alertData['studentName'] ?? 'Unknown Student';
      final studentId = alertData['studentId'] ?? '';
      final location = alertData['location'] ?? 'Unknown Location';

      print('📞 Alert from: $studentName ($studentId) at $location');

      // FOR TESTING: Use dummy phone numbers
      final List<String> testPhones = ['+8801714721112'];
      print('📞 TEST MODE: Will call ${testPhones.length} test numbers');

      int callsInitiated = 0;

      for (final phone in testPhones) {
        try {
          // Use native Android auto-call (no user interaction needed)
          await NativeCall.makeCall(phone: phone);
          callsInitiated++;
          print('✅ Automatic call initiated to $phone');

          // Small delay between calls
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          print('❌ Error making automatic call to $phone: $e');
        }
      }

      /* PRODUCTION CODE - Uncomment to call real proctors:
      // Query proctors from Firestore
      final proctorSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'proctorial')
          .get();

      print('📞 Found ${proctorSnapshot.docs.length} proctors');

      int callsInitiated = 0;

      for (final proctorDoc in proctorSnapshot.docs) {
        final proctorData = proctorDoc.data();
        final phone = proctorData['phoneNumber'] as String?;

        if (phone == null || phone.isEmpty) continue;

        try {
          // Use native Android auto-call (no user interaction needed)
          await NativeCall.makeCall(phone: phone);
          callsInitiated++;
          print('✅ Automatic call initiated to $phone');
            
          // Small delay between calls (2 seconds)
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          print('❌ Error making automatic call to $phone: $e');
        }
      }
      */

      // Mark alert as call escalated
      await FirebaseFirestore.instance
          .collection('proctorial_alerts')
          .doc(alertId)
          .update({
            'callEscalated': true,
            'callEscalatedAt': FieldValue.serverTimestamp(),
            'callsInitiated': callsInitiated,
          });

      print('✅ Call escalation completed: $callsInitiated calls initiated');
    } catch (e) {
      print('❌ Error in call escalation: $e');
    }
    // DON'T auto-resume volume buttons - let the app lifecycle handle it
    // Auto-resuming causes false triggers when returning from call UI
  }
}

/// Countdown dialog widget for call escalation
class _CallCountdownDialog extends StatefulWidget {
  final String alertId;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _CallCountdownDialog({
    required this.alertId,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  State<_CallCountdownDialog> createState() => _CallCountdownDialogState();
}

class _CallCountdownDialogState extends State<_CallCountdownDialog> {
  int _countdown = AppConstants.callCountdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    print('⏱️ Call countdown dialog: Starting $_countdown-second countdown');
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
        print('⏱️ Call countdown: $_countdown seconds remaining');
      } else {
        print(
          '⏱️ Call countdown finished - closing dialog and initiating calls',
        );
        timer.cancel();
        Navigator.of(context).pop(); // Close dialog first
        widget.onComplete(); // Then initiate calls
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.phone, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text('Call Escalation'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Alert still not accepted!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'SMS sent but no response.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          Text(
            'Calling proctors in $_countdown seconds...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Cancel if the situation is resolved.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
            widget.onCancel();
          },
          child: Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop(); // Close dialog first
            widget.onComplete(); // Then initiate calls
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Call Now'),
        ),
      ],
    );
  }
}
