import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Event-based location service - captures GPS only when needed
/// No background tracking = Better battery life + OEM-safe
class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  // Cached location (available after first event)
  Position? _lastKnownPosition;
  DateTime? _lastUpdateTime;

  // NSTU Campus center fallback
  static const double _nstuLatitude = 22.8696;
  static const double _nstuLongitude = 91.0995;

  /// Get cached latitude (never returns 0.0)
  double get latitude => _lastKnownPosition?.latitude ?? _nstuLatitude;

  /// Get cached longitude (never returns 0.0)
  double get longitude => _lastKnownPosition?.longitude ?? _nstuLongitude;

  /// Check if we have a valid cached location
  bool get hasValidLocation => _lastKnownPosition != null;

  /// Check if cached location is fresh (< 5 minutes old)
  bool get isLocationFresh {
    if (_lastUpdateTime == null) return false;
    final age = DateTime.now().difference(_lastUpdateTime!);
    return age.inMinutes < 5;
  }

  /// Get age of cached location in seconds
  int get locationAgeSeconds {
    if (_lastUpdateTime == null) return -1;
    return DateTime.now().difference(_lastUpdateTime!).inSeconds;
  }

  /// Event-based location capture (called on app open, resume, etc.)
  /// Quick capture with configurable timeout
  Future<Position?> captureLocation({
    bool highAccuracy = false,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      // Check permission first
      var status = await Permission.location.status;
      if (!status.isGranted) {
        status = await Permission.location.request();
        if (!status.isGranted) {
          debugPrint('⚠️ Location permission denied');
          return null;
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: highAccuracy
            ? LocationAccuracy
                  .best // ±5m (for SOS)
            : LocationAccuracy.high, // ±10m (for routine)
      ).timeout(timeout);

      // Validate coordinates
      if (_isValidLocation(position.latitude, position.longitude)) {
        _lastKnownPosition = position;
        _lastUpdateTime = DateTime.now();
        debugPrint(
          '📍 GPS captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (±${position.accuracy.toStringAsFixed(1)}m)',
        );
        return position;
      } else {
        debugPrint('⚠️ Invalid GPS coordinates rejected');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ GPS capture failed: $e');
      return null; // Caller will use cached or fallback
    }
  }

  /// Force high-accuracy capture for emergency (SOS alerts)
  /// Guarantees valid coordinates - never returns null
  Future<Position> captureForEmergency() async {
    debugPrint('🚨 Emergency location capture started');

    try {
      // Try high-accuracy GPS first (3 second timeout)
      final position = await captureLocation(
        highAccuracy: true,
        timeout: const Duration(seconds: 3),
      );

      if (position != null) {
        debugPrint('✅ Fresh high-accuracy GPS for alert');
        return position;
      }

      // Fallback to cached if available and fresh
      if (_lastKnownPosition != null && isLocationFresh) {
        debugPrint(
          '✅ Using cached location (${locationAgeSeconds}s old) for alert',
        );
        return _lastKnownPosition!;
      }

      // Fallback to any cached location (even if old)
      if (_lastKnownPosition != null) {
        debugPrint(
          '⚠️ Using stale cached location (${locationAgeSeconds}s old) for alert',
        );
        return _lastKnownPosition!;
      }

      // Final fallback: NSTU campus center
      debugPrint('⚠️ Using NSTU campus fallback for alert');
      return _createFallbackPosition();
    } catch (e) {
      debugPrint('❌ Emergency capture error: $e - using fallback');
      return _createFallbackPosition();
    }
  }

  /// Get best available location for alert (synchronous)
  /// Uses cached location or fallback - never blocks
  Position getBestAvailableLocation() {
    if (_lastKnownPosition != null) {
      if (isLocationFresh) {
        debugPrint(
          '📍 Using fresh cached location (${locationAgeSeconds}s old)',
        );
      } else {
        debugPrint(
          '📍 Using stale cached location (${locationAgeSeconds}s old)',
        );
      }
      return _lastKnownPosition!;
    }

    debugPrint('📍 No cached location - using NSTU campus fallback');
    return _createFallbackPosition();
  }

  /// Validate coordinates (reject 0,0 and outside Bangladesh)
  bool _isValidLocation(double lat, double lon) {
    // Reject null island (0, 0)
    if (lat == 0.0 && lon == 0.0) return false;

    // Bangladesh bounding box
    // Latitude: 20.5°N to 26.6°N
    // Longitude: 88.0°E to 92.7°E
    if (lat < 20.5 || lat > 26.6) return false;
    if (lon < 88.0 || lon > 92.7) return false;

    return true;
  }

  /// Create fallback position (NSTU campus center)
  Position _createFallbackPosition() {
    return Position(
      latitude: _nstuLatitude,
      longitude: _nstuLongitude,
      timestamp: DateTime.now(),
      accuracy: 50.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// Get location status for UI display
  String getLocationStatus() {
    if (!hasValidLocation) {
      return 'Requesting location...';
    }

    if (isLocationFresh) {
      return 'Real-time GPS ready (${locationAgeSeconds}s ago)';
    }

    final minutes = (locationAgeSeconds / 60).floor();
    if (minutes < 60) {
      return 'GPS cached (${minutes}m ago)';
    }

    return 'GPS outdated - will refresh on alert';
  }

  /// Clear cached location (for testing)
  void clearCache() {
    _lastKnownPosition = null;
    _lastUpdateTime = null;
    debugPrint('🗑️ Location cache cleared');
  }
}
