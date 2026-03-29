import 'package:flutter/services.dart';

/// Native Android auto-call wrapper using Platform Channel
class NativeCall {
  static const platform = MethodChannel('com.safelink.sms/native');

  /// Make an automatic phone call (requires CALL_PHONE permission)
  static Future<String> makeCall({required String phone}) async {
    try {
      print('📞 Calling native Android makeCall with phone: $phone');

      final String result = await platform.invokeMethod('makeCall', {
        'phone': phone,
      });

      print('✅ Native call result: $result');
      return result;
    } on PlatformException catch (e) {
      print('❌ Platform exception: ${e.code} - ${e.message}');
      if (e.code == 'PERMISSION_DENIED') {
        throw Exception(
          'Call permission denied. Please grant CALL_PHONE permission.',
        );
      }
      throw Exception('Failed to make call: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Unexpected error making call: $e');
    }
  }

  /// Check if CALL_PHONE permission is granted
  static Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await platform.invokeMethod(
        'checkCallPermission',
      );
      print('📞 Call permission status: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('❌ Error checking call permission: $e');
      return false;
    }
  }

  /// Make calls to multiple phone numbers with delays between calls
  static Future<void> makeBulkCalls({
    required List<String> phones,
    int delaySeconds = 2,
  }) async {
    print('📞 Making bulk calls to ${phones.length} numbers');

    for (int i = 0; i < phones.length; i++) {
      final phone = phones[i];
      try {
        await makeCall(phone: phone);
        print('✅ Call $i/${phones.length} initiated to $phone');

        // Delay between calls (except after last call)
        if (i < phones.length - 1) {
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      } catch (e) {
        print('❌ Failed to call $phone: $e');
        // Continue with next phone number even if one fails
      }
    }

    print('✅ Bulk call completed: ${phones.length} calls attempted');
  }
}
