import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert_model.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();

  AlertService._internal();

  static AlertService get instance => _instance;

  // Production Firebase Cloud Functions URL
  static const String baseUrl =
      'https://us-central1-safe-93f85.cloudfunctions.net';

  // For local testing with Firebase Emulators (uncomment to use):
  // static const String baseUrl = 'http://localhost:5001/safe-93f85/us-central1';

  /// Send SOS alert to proctorial body
  ///
  /// This sends the student's emergency alert with their current location,
  /// name, ID, department, and session to the backend for proctorial body notification.
  /// All data is fetched fresh from Firestore to ensure accuracy.
  Future<bool> sendSosAlert({
    required AlertModel alert,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/sendSosAlert');

      // Log the alert data being sent (for verification)
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🚨 SENDING SOS ALERT TO PROCTORIAL BODY');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Student ID: ${alert.studentId}');
      print('Student Name: ${alert.studentName}');
      print('Department: ${alert.department}');
      print('Session: ${alert.session}');
      print('Phone: ${alert.studentPhone}');
      print('Email: ${alert.studentEmail}');
      print('Location: ${alert.location}');
      print('GPS: ${alert.latitude}, ${alert.longitude}');
      print('Time: ${alert.timestamp}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(alert.toJson()),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ SOS alert sent successfully to backend');
        print('Response: ${response.body}');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Invalid authentication token');
      } else if (response.statusCode == 400) {
        throw Exception('Bad request - ${response.body}');
      } else {
        throw Exception(
          'Failed to send alert - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error sending SOS alert: $e');
      // Return true anyway so the alert is saved locally
      // The backend sync will retry when connection is available
      return false;
    }
  }

  /// Get all alerts for a student
  Future<List<AlertModel>> getStudentAlerts({
    required String studentId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/alerts?studentId=$studentId');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => AlertModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch alerts');
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }

  /// Get alert by ID
  Future<AlertModel?> getAlert({
    required String alertId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/alerts/$alertId');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AlertModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching alert: $e');
      return null;
    }
  }

  /// Acknowledge alert received (for proctorial body)
  Future<bool> acknowledgeAlert({
    required String alertId,
    required String acknowledgedBy,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/alerts/$alertId/acknowledge');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'acknowledgedBy': acknowledgedBy,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Error acknowledging alert: $e');
      return false;
    }
  }

  /// Accept alert (mark as accepted by security/proctor)
  Future<bool> acceptAlert({
    required String alertId,
    required String acceptedBy,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/alerts/$alertId/accept');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'acceptedBy': acceptedBy,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting alert: $e');
      return false;
    }
  }

  /// Reject alert (mark as rejected by security/proctor)
  Future<bool> rejectAlert({
    required String alertId,
    required String rejectedBy,
    required String reason,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/alerts/$alertId/reject');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'rejectedBy': rejectedBy,
              'reason': reason,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting alert: $e');
      return false;
    }
  }

  /// Forward alert to security (called by proctorial body)
  Future<bool> forwardAlertToSecurity({
    required String alertId,
    required String forwardedBy,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/alerts/$alertId/forward-to-security');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'forwardedBy': forwardedBy,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Error forwarding alert: $e');
      return false;
    }
  }
}
