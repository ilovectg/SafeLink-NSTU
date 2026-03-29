import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to send SMS alerts via Twilio through Firebase Cloud Functions
class TwilioSmsService {
  static final TwilioSmsService _instance = TwilioSmsService._internal();
  TwilioSmsService._internal();
  static TwilioSmsService get instance => _instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send emergency SMS alert to guardian/contact
  ///
  /// [phoneNumber] - Recipient phone (must include country code, e.g., +8801322260557)
  /// [studentName] - Name of student in emergency
  /// [location] - Current location of student
  /// [alertType] - Type of alert ('shake', 'button', 'manual')
  Future<Map<String, dynamic>> sendEmergencySMS({
    required String phoneNumber,
    required String studentName,
    required String location,
    String alertType = 'shake',
  }) async {
    try {
      print('📤 Calling Twilio SMS function...');
      print('   Phone: $phoneNumber');
      print('   Student: $studentName');
      print('   Location: $location');
      print('   Alert Type: $alertType');

      // Ensure user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call Firebase Cloud Function
      final callable = _functions.httpsCallable('sendShakeAlertSMS');
      final response = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
        'studentName': studentName,
        'location': location,
        'alertType': alertType,
      });

      final data = response.data;

      if (data['success'] == true) {
        print('✅ SMS sent successfully!');
        print('   Message SID: ${data['messageSid']}');
        print('   Sent to: ${data['sentTo']}');
        return {
          'success': true,
          'messageSid': data['messageSid'],
          'sentTo': data['sentTo'],
        };
      } else {
        print('❌ SMS sending failed: ${data['error']}');
        return {'success': false, 'error': data['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      print('❌ Error calling SMS function: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send SMS to multiple recipients (guardians, security, etc.)
  Future<List<Map<String, dynamic>>> sendBulkEmergencySMS({
    required List<String> phoneNumbers,
    required String studentName,
    required String location,
    String alertType = 'shake',
  }) async {
    print('📤 Sending bulk SMS to ${phoneNumbers.length} recipients...');

    final results = <Map<String, dynamic>>[];

    for (final phone in phoneNumbers) {
      try {
        final result = await sendEmergencySMS(
          phoneNumber: phone,
          studentName: studentName,
          location: location,
          alertType: alertType,
        );
        results.add(result);

        // Add small delay between messages to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('❌ Failed to send to $phone: $e');
        results.add({
          'success': false,
          'phoneNumber': phone,
          'error': e.toString(),
        });
      }
    }

    final successCount = results.where((r) => r['success'] == true).length;
    print(
      '✅ Bulk SMS complete: $successCount/${phoneNumbers.length} sent successfully',
    );

    return results;
  }
}
