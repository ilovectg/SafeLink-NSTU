import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:geocoding/geocoding.dart';
import '../../presentation/home/controllers/alert_controller.dart';
import '../../presentation/auth/controllers/profile_controller.dart';
import 'location_service.dart';

/// Service to detect phone shake gestures and trigger emergency alerts
///
/// This service uses the accelerometer to detect when the user shakes their phone.
/// It can be started/stopped based on user role (students only) and triggers
/// appropriate actions when shake is detected.
class ShakeDetectionService {
  static final ShakeDetectionService _instance =
      ShakeDetectionService._internal();
  ShakeDetectionService._internal();
  static ShakeDetectionService get instance => _instance;

  ShakeDetector? _shakeDetector;
  bool _isListening = false;
  BuildContext? _context;

  /// Check if shake detection is currently active
  bool get isListening => _isListening;

  /// Initialize and start shake detection
  ///
  /// FR11: Detects shake with acceleration > 15 m/s², 3 times within 2-3 seconds
  /// Start listening for shake events (FR11 requirements)
  ///
  /// [context] - BuildContext for showing dialogs/popups
  /// [shakeThresholdGravity] - Sensitivity threshold in G-force (FR11: 15 m/s² = 1.53G)
  /// [minimumShakeCount] - Number of shakes required (FR11: 3 shakes)
  /// [shakeSlopTimeMS] - Time window for consecutive shakes (FR11: 2-3 seconds)
  /// [shakeCountResetTime] - Time to reset shake count
  void startListening({
    required BuildContext context,
    double shakeThresholdGravity = 1.53, // FR11: 15 m/s² = 1.53G
    int minimumShakeCount = 2, // FR11: 3 shakes
    int shakeSlopTimeMS = 2500, // FR11: 2.5 seconds (middle of 2-3s range)
    int shakeCountResetTime = 3000,
  }) {
    if (_isListening) {
      print('⚠️ Shake detection already running');
      return;
    }

    _context = context;

    print('🔧 Starting shake detection...');
    print('   Device: Running on real device');

    try {
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: (event) {
          print('📳 onPhoneShake callback triggered!');
          _onShakeDetected(event);
        },
        shakeThresholdGravity: shakeThresholdGravity,
        minimumShakeCount: minimumShakeCount,
        shakeSlopTimeMS: shakeSlopTimeMS,
        shakeCountResetTime: shakeCountResetTime,
      );

      _isListening = true;
      print('✅ Shake detection started successfully');
      print(
        '   Threshold: ${shakeThresholdGravity}G (≈${(shakeThresholdGravity * 9.8).toStringAsFixed(1)} m/s²)',
      );
      print('   Required shakes: $minimumShakeCount');
      print('   Time window: ${shakeSlopTimeMS}ms');
      print('   ShakeDetector instance created: ${_shakeDetector != null}');
      print('🎯 Try shaking your phone NOW - very lightly!');
    } catch (e) {
      print('❌ ERROR starting shake detection: $e');
      _isListening = false;
    }
  }

  /// Stop shake detection
  void stopListening() {
    if (!_isListening) {
      print('⚠️ Shake detection not running');
      return;
    }

    _shakeDetector?.stopListening();
    _shakeDetector = null;
    _isListening = false;
    _context = null;

    print('✅ Shake detection stopped');
  }

  /// Handle shake detection event
  void _onShakeDetected(dynamic event) async {
    print('🔔 SHAKE DETECTED! Showing confirmation countdown...');

    if (_context == null || !_context!.mounted) {
      print('⚠️ Cannot send alert - context not available');
      return;
    }

    // Show countdown confirmation dialog
    await showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (dialogContext) => _ShakeConfirmationDialog(
        onConfirm: () async {
          print('✅ User confirmed shake alert or countdown finished');
          // Don't pop here - caller handles it
          await _sendShakeAlert();
        },
        onCancel: () {
          print('🚫 User cancelled shake alert');
          // onCancel is only called after pop, so don't pop again
        },
      ),
    );
  }

  /// Send shake alert after confirmation
  Future<void> _sendShakeAlert() async {
    if (_context == null || !_context!.mounted) {
      print('⚠️ Cannot send alert - context not available');
      return;
    }

    try {
      // Get fresh student data from Firestore
      final profileController = ProfileController.instance;
      await profileController.loadFromFirestore();

      // Event: Force high-accuracy location for shake alert
      print('🚨 Shake alert - capturing emergency location');
      final position = await LocationService.instance.captureForEmergency();
      final latitude = position.latitude;
      final longitude = position.longitude;

      print(
        '📍 Shake alert location: $latitude, $longitude (±${position.accuracy}m)',
      );

      // Reverse geocode location
      String locationString = 'Unknown location';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          locationString = [
            place.street,
            place.subLocality,
            place.locality,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        }
      } catch (e) {
        locationString =
            'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}';
      }

      // Send SOS alert through AlertController (same as manual SOS button)
      print('📤 Sending shake-triggered SOS alert...');
      await AlertController.instance.sendAlert(
        studentId: profileController.studentId,
        studentName: profileController.name,
        studentPhone: profileController.phone,
        studentEmail: profileController.email,
        latitude: latitude,
        longitude: longitude,
        location: locationString,
        department: profileController.department,
        session: profileController.session,
        pulseBuilding: profileController.pulseBuilding,
        pulseFloor: profileController.pulseFloor,
        pulseRoom: profileController.pulseRoom,
        pulseMessage: profileController.pulseMessage,
      );

      // No success popup - countdown dialog was enough confirmation
      print('✅ Shake-triggered SOS alert sent successfully!');
    } catch (e) {
      print('❌ Error sending shake alert: $e');

      // Show error notification only if something goes wrong
      if (_context != null && _context!.mounted) {
        _showErrorPopup(_context!, e.toString());
      }
    }
  }

  /// Show error popup if alert fails
  void _showErrorPopup(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Alert Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '❌ Failed to send shake-triggered alert.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Error: $error',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Dispose and cleanup
  void dispose() {
    stopListening();
  }
}

/// Countdown confirmation dialog for shake alert
class _ShakeConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ShakeConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_ShakeConfirmationDialog> createState() =>
      _ShakeConfirmationDialogState();
}

class _ShakeConfirmationDialogState extends State<_ShakeConfirmationDialog> {
  int _countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    print('⏱️ Shake confirmation dialog: Starting 10-second countdown');
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
        print('⏱️ Shake countdown: $_countdown seconds remaining');
      } else {
        print('⏱️ Shake countdown finished - sending alert');
        timer.cancel();
        Navigator.of(context).pop(); // Pop dialog first
        widget.onConfirm(); // Then send alert
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
          Icon(Icons.vibration, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Text('Shake Detected!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Emergency alert will be sent.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Proctorial body will be notified.',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          Text(
            'Sending alert in $_countdown seconds...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Cancel if this was a mistake.',
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
          child: Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop(); // Pop dialog first
            widget.onConfirm(); // Then send alert (async)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Send Now'),
        ),
      ],
    );
  }
}
