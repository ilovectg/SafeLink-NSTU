import 'package:flutter/services.dart';

/// Native Android SMS sender using Platform Channel
class NativeSms {
  static const platform = MethodChannel('com.safelink.sms/native');

  /// Check if SMS permission is granted
  static Future<bool> checkPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkSmsPermission');
      return result;
    } catch (e) {
      print('❌ Error checking SMS permission: $e');
      return false;
    }
  }

  /// Send SMS using native Android SmsManager
  /// Returns true if SMS was sent successfully
  static Future<bool> sendSMS({
    required String phone,
    required String message,
  }) async {
    try {
      print('📤 Calling native Android SMS for: $phone');

      final String result = await platform.invokeMethod('sendSMS', {
        'phone': phone,
        'message': message,
      });

      print('✅ Native SMS result: $result');
      return true;
    } on PlatformException catch (e) {
      print('❌ Platform Exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Error sending native SMS: $e');
      return false;
    }
  }

  /// Send SMS to multiple recipients
  static Future<int> sendBulkSMS({
    required List<String> phones,
    required String message,
  }) async {
    int successCount = 0;

    for (final phone in phones) {
      final success = await sendSMS(phone: phone, message: message);
      if (success) {
        successCount++;
        // Small delay between SMS
        await Future.delayed(Duration(milliseconds: 500));
      }
    }

    return successCount;
  }
}
