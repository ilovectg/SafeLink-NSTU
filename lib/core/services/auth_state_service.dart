import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage authentication state persistence using SharedPreferences.
/// This service stores minimal user information for routing decisions on app restart.
///
/// Security Note: SharedPreferences is NOT encrypted. Only store non-sensitive data.
/// Real authentication is always verified through Firebase Auth.
class AuthStateService {
  // Singleton pattern
  static final AuthStateService _instance = AuthStateService._internal();
  factory AuthStateService() => _instance;
  AuthStateService._internal();

  static AuthStateService get instance => _instance;

  // SharedPreferences keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserUid = 'user_uid';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyLastLoginTime = 'last_login_time';

  /// Save login state after successful authentication
  ///
  /// [uid] - Firebase user UID
  /// [email] - User email address
  /// [role] - User role: 'student', 'proctorial', or 'security'
  Future<void> saveLoginState({
    required String uid,
    required String email,
    required String role,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();

      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyUserUid, uid);
      await prefs.setString(_keyUserEmail, email);
      await prefs.setString(_keyUserRole, role.toLowerCase());
      await prefs.setString(_keyLastLoginTime, timestamp);

      print('[AuthState] Login state saved - Role: $role, UID: $uid');
    } catch (e) {
      print('[AuthState] Error saving login state: $e');
    }
  }

  /// Get saved login state
  ///
  /// Returns a map containing login information or null if not logged in
  Future<Map<String, String>?> getLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (!isLoggedIn) {
        return null;
      }

      final uid = prefs.getString(_keyUserUid);
      final email = prefs.getString(_keyUserEmail);
      final role = prefs.getString(_keyUserRole);
      final lastLoginTime = prefs.getString(_keyLastLoginTime);

      // Validate required fields
      if (uid == null || email == null || role == null) {
        print('[AuthState] Incomplete login state, clearing...');
        await clearLoginState();
        return null;
      }

      return {
        'uid': uid,
        'email': email,
        'role': role,
        'lastLoginTime': lastLoginTime ?? '',
      };
    } catch (e) {
      print('[AuthState] Error getting login state: $e');
      return null;
    }
  }

  /// Check if user is logged in (quick check)
  ///
  /// Returns true if login state exists in SharedPreferences
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      print('[AuthState] Error checking login state: $e');
      return false;
    }
  }

  /// Get just the saved user role for quick routing decisions
  ///
  /// Returns 'student', 'proctorial', 'security', or null
  Future<String?> getSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (!isLoggedIn) {
        return null;
      }

      return prefs.getString(_keyUserRole);
    } catch (e) {
      print('[AuthState] Error getting saved role: $e');
      return null;
    }
  }

  /// Clear login state on logout
  ///
  /// Removes all authentication-related data from SharedPreferences
  Future<void> clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserUid);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserRole);
      await prefs.remove(_keyLastLoginTime);

      print('[AuthState] Login state cleared');
    } catch (e) {
      print('[AuthState] Error clearing login state: $e');
    }
  }

  /// Get saved user UID
  Future<String?> getSavedUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserUid);
    } catch (e) {
      print('[AuthState] Error getting saved UID: $e');
      return null;
    }
  }

  /// Get saved user email
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('[AuthState] Error getting saved email: $e');
      return null;
    }
  }
}
