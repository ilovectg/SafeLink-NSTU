import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/controllers/profile_controller.dart';
import 'controllers/alert_controller.dart';
import 'alert_notifications_screen.dart';
import '../../core/services/shake_detection_service.dart';
import '../../core/services/volume_button_sos_service.dart';
import '../../core/services/sms_escalation_service.dart';
import '../../core/services/call_escalation_service.dart';
import '../../core/services/location_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _sending = false;
  String _locationStatus = 'Finding your location...';
  int _currentIndex = 0;
  late AnimationController _pulseController;
  StreamSubscription<Position>? _liveLocationSub;
  Timer? _volumeResumeTimer; // Timer for delayed volume button resume

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer to detect app resume
    WidgetsBinding.instance.addObserver(this);

    // Load student profile data from SharedPreferences and Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ProfileController.instance.loadFromPrefs();
      await ProfileController.instance.loadFromFirestore();
    });

    // Event 1: Capture location on app open
    _captureInitialLocation();
    // Initialize real-time listener for alerts
    AlertController.instance.initializeRealtimeListener();
    // Set auth token for backend communication
    _setAuthToken();
    // Start volume button SOS detection (FR12)
    VolumeButtonSosService.instance.startListening();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Set SMS escalation context (needs context, so delayed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SmsEscalationService.instance.setContext(context);
        CallEscalationService.instance.setContext(context);
        VolumeButtonSosService.instance.setContext(context);
      }
    });
  }

  @override
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed - checking volume button service state');

      // Event 2: App resumed from background - refresh location
      LocationService.instance.captureLocation().then((_) {
        if (mounted) {
          setState(() {
            _locationStatus = LocationService.instance.getLocationStatus();
          });
        }
      });

      // Check if volume service is listening but paused
      if (VolumeButtonSosService.instance.isListening &&
          VolumeButtonSosService.instance.isPaused) {
        print('⏰ Volume buttons paused - scheduling resume in 30 seconds');

        // Cancel any existing timer
        _volumeResumeTimer?.cancel();

        // Resume after 30 seconds to avoid false triggers from call UI
        _volumeResumeTimer = Timer(Duration(seconds: 30), () {
          if (VolumeButtonSosService.instance.isListening &&
              VolumeButtonSosService.instance.isPaused) {
            print('▶️ Auto-resuming volume buttons after app resume');
            VolumeButtonSosService.instance.resume();
          }
        });
      }
    }
  }

  /// Set Firebase auth token for AlertController
  Future<void> _setAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          AlertController.instance.setAuthToken(token);
          print('✅ Auth token set for AlertController');
        }
      }
    } catch (e) {
      print('⚠️ Error setting auth token: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    print('🔍 StudentProfileScreen didChangeDependencies called');
    print(
      '   Shake service already listening: ${ShakeDetectionService.instance.isListening}',
    );

    // Initialize shake detection for students (FR11, FR25)
    if (!ShakeDetectionService.instance.isListening) {
      print('✅ Initializing shake detection for student');
      // Use addPostFrameCallback to ensure context is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShakeDetectionService.instance.startListening(context: context);
          print('✅ Shake detection initialized and started');
        } else {
          print('⚠️ Widget not mounted, cannot start shake detection');
        }
      });
    } else {
      print('ℹ️ Shake detection already listening, skipping initialization');
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Cancel volume resume timer
    _volumeResumeTimer?.cancel();

    _liveLocationSub?.cancel();
    _pulseController.dispose();
    // Stop shake detection when leaving student profile
    ShakeDetectionService.instance.stopListening();
    print('✅ Shake detection stopped on dispose');
    // Stop volume button SOS detection
    VolumeButtonSosService.instance.clearContext();
    VolumeButtonSosService.instance.stopListening();
    print('✅ Volume button SOS stopped on dispose');
    // Clear SMS escalation context and cancel timers
    SmsEscalationService.instance.clearContext();
    SmsEscalationService.instance.cancelAllEscalations();
    CallEscalationService.instance.clearContext();
    CallEscalationService.instance.cancelAllEscalations();
    print('✅ SMS and Call escalation services stopped on dispose');
    print('✅ SMS escalation monitoring stopped on dispose');
    super.dispose();
  }

  Future<void> _captureInitialLocation() async {
    // Event-based capture: Get location on app open
    await LocationService.instance.captureLocation();

    if (mounted) {
      setState(() {
        _locationStatus = LocationService.instance.getLocationStatus();
      });
    }
  }

  void _openAlertsScreen() {
    // Always open Alert Notifications Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlertNotificationsScreen()),
    );
  }

  Future<void> _showMapOptions() async {
    double? latitude;
    double? longitude;

    // Always try to get current GPS location for accurate position
    try {
      var locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        locationStatus = await Permission.location.request();
      }

      if (locationStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Getting your current location...'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Get current position with best accuracy
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 10),
        );
        latitude = position.latitude;
        longitude = position.longitude;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Showing your current location'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Permission denied, use default NSTU location
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Showing NSTU campus.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        latitude = 22.8719;
        longitude = 91.0987;
      }
    } catch (e) {
      print('Error getting location: $e');
      // On error, use default NSTU location
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Showing NSTU campus.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      latitude = 22.8719;
      longitude = 91.0987;
    }

    // Open in Google Maps (will always have a location now)
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.emergency, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Confirm Emergency'),
          ],
        ),
        content: const Text('Send emergency alert to your proctorial body?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);

    // Prepare variables outside try so they are in scope for Firestore updates
    String alertId = '';

    try {
      // Fetch fresh student data from Firestore to ensure real-time accuracy
      final profileController = ProfileController.instance;
      await profileController.loadFromFirestore();

      // Event 3: Force high-accuracy location capture for emergency
      final position = await LocationService.instance.captureForEmergency();
      final latitude = position.latitude;
      final longitude = position.longitude;

      print(
        '🚨 Alert location: $latitude, $longitude (±${position.accuracy}m)',
      );

      // Build a fresh location string from the current coordinates (reverse geocode best-effort)
      final locString = await _reverseGeocode(latitude, longitude);
      if (mounted) {
        setState(() {
          _locationStatus = locString;
        });
      }

      // Send alert through AlertController with REAL student information from Firestore
      await AlertController.instance.sendAlert(
        studentId: profileController.studentId,
        studentName: profileController.name,
        studentPhone: profileController.phone,
        studentEmail: profileController.email,
        latitude: latitude,
        longitude: longitude,
        location: locString,
        department: profileController.department,
        session: profileController.session,
        pulseBuilding: profileController.pulseBuilding,
        pulseFloor: profileController.pulseFloor,
        pulseRoom: profileController.pulseRoom,
        pulseMessage: profileController.pulseMessage,
      );

      // Get the alert ID from the most recent alert
      alertId = AlertController.instance.alerts.isNotEmpty
          ? AlertController.instance.alerts.last.id
          : '';

      // Push latest location info into proctorial_alerts for live view
      if (alertId.isNotEmpty) {
        try {
          await FirebaseFirestore.instance
              .collection('proctorial_alerts')
              .doc(alertId)
              .update({
                'liveLatitude': latitude,
                'liveLongitude': longitude,
                'liveLocationName': locString,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          _startLiveLocationUpdates(alertId);
        } catch (e) {
          print('⚠️ Could not update live location: $e');
        }
      }
    } catch (e) {
      print('Error preparing SOS alert: $e');
      setState(() => _sending = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sending = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Emergency alert sent successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Alert sent - waiting for real response from security/proctor
    // No auto-accept - alerts must be manually handled by security personnel
  }

  void _startLiveLocationUpdates(String alertId) {
    _liveLocationSub?.cancel();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10, // update after ~10m movement for better tracking
    );

    _liveLocationSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (pos) async {
            try {
              final locString = await _reverseGeocode(
                pos.latitude,
                pos.longitude,
              );

              await FirebaseFirestore.instance
                  .collection('proctorial_alerts')
                  .doc(alertId)
                  .update({
                    'liveLatitude': pos.latitude,
                    'liveLongitude': pos.longitude,
                    'liveLocationName': locString,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

              if (mounted) {
                setState(() {
                  _locationStatus = locString;
                });
              }
            } catch (e) {
              print('⚠️ Live location stream update failed: $e');
            }
          },
          onError: (e) {
            print('⚠️ Live location stream error: $e');
          },
        );
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.name != null && p.name!.isNotEmpty) p.name,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea,
          if (p.country != null && p.country!.isNotEmpty) p.country,
        ];
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      print('⚠️ Reverse geocoding failed: $e');
    }
    // Fallback to raw lat/lon
    return 'Lat: ${lat.toStringAsFixed(6)}, Lon: ${lon.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1115)
          : const Color(0xFFE9F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6EB9F9), Color(0xFF2386DC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 7,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/splash_logo.png',
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.shield,
                                  color: Color(0xFF2196F3),
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'SafeLink',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'NSTU',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                        child: Container(
                          padding: const EdgeInsets.all(2.2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 9,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6EB9F9), Color(0xFF2386DC)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Welcome message section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: ListenableBuilder(
                  listenable: ProfileController.instance,
                  builder: (context, child) {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF6D6D6D),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ProfileController.instance.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Emergency section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Builder(
                  builder: (ctx) {
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    return Column(
                      children: [
                        Text(
                          'Are you in emergency?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A1A),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Press the button below, help will reach you soon',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Enhanced SOS Button with animation
                        GestureDetector(
                          onTap: _sending ? null : _sendSos,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF1744)
                                          .withOpacity(
                                            0.4 + _pulseController.value * 0.3,
                                          ),
                                      blurRadius:
                                          40 + _pulseController.value * 20,
                                      spreadRadius:
                                          5 + _pulseController.value * 15,
                                    ),
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF1744,
                                      ).withOpacity(0.2),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFFFF5252),
                                        Color(0xFFFF1744),
                                        Color(0xFFD50000),
                                      ],
                                      stops: [0.0, 0.5, 1.0],
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 6,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 85,
                                    backgroundColor: Colors.transparent,
                                    child: _sending
                                        ? const SizedBox(
                                            width: 65,
                                            height: 65,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                              strokeWidth: 5,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.warning_rounded,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'SOS',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 3,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black26,
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Location section with enhanced design
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Builder(
                  builder: (ctx) {
                    final isDark = Theme.of(ctx).brightness == Brightness.dark;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withOpacity(0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your current address',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF9E9E9E),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _locationStatus,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home_rounded, 0, Colors.redAccent),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    Icons.map_rounded,
                    1,
                    Colors.deepPurpleAccent,
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                    Icons.notifications_rounded,
                    2,
                    Colors.deepOrangeAccent,
                  ),
                  label: '',
                ),
              ],
              currentIndex: _currentIndex,
              selectedItemColor: const Color(0xFF1E88E5),
              unselectedItemColor: const Color(0xFF9E9E9E),
              selectedFontSize: 11.5,
              unselectedFontSize: 10.5,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                if (index == 1) {
                  // View Map button tapped
                  _showMapOptions();
                } else if (index == 2) {
                  // Open notifications
                  _openAlertsScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, Color color) {
    final isSelected = _currentIndex == index;
    final gradient = LinearGradient(
      colors: [
        color.withOpacity(isSelected ? 0.95 : 0.75),
        color.withOpacity(isSelected ? 0.85 : 0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    Widget circle = Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );

    Widget iconWithBadge = circle;
    if (index == 2) {
      iconWithBadge = ListenableBuilder(
        listenable: AlertController.instance,
        builder: (context, _) {
          final count = AlertController.instance.unreadNotificationCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              circle,
              if (count > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWithBadge,
        const SizedBox(height: 6),
        Builder(
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Text(
              _navLabel(index),
              style: TextStyle(
                fontSize: isSelected ? 11.5 : 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white54 : const Color(0xFF6D6D6D)),
              ),
            );
          },
        ),
      ],
    );
  }

  String _navLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'View Map';
      case 2:
        return 'Notification';
      default:
        return '';
    }
  }
}
