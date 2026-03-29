# Persistent Login Implementation Plan

## Overview
Implement persistent login state using SharedPreferences and Firebase Authentication to keep users logged in after app restart.

## Current State Analysis

### ✅ Already Available
1. **SharedPreferences Package**: `shared_preferences: ^2.2.2` installed
2. **ProfileController**: Already uses SharedPreferences for profile data
3. **Firebase Authentication**: Active and working
4. **Routing Structure**: 
   - Splash → Welcome → Login → StudentProfile/Home
   - Students go to `/student-profile`
   - Proctorial/Security go to `/home` with role argument

### ❌ Missing
- No login state persistence in splash screen
- No auth check on app restart
- Users always redirected to welcome screen
- No logout state management

## Solution Architecture

```
App Start (main.dart)
   ↓
SplashScreen (5 seconds animation)
   ↓
Check Authentication State:
   ├─ FirebaseAuth.currentUser != null?
   │  ├─ YES → Get saved role from SharedPreferences
   │  │         ├─ Role = 'student' → Navigate to /student-profile
   │  │         ├─ Role = 'proctorial' → Navigate to /home (args: 'proctorial body')
   │  │         ├─ Role = 'security' → Navigate to /home (args: 'security body')
   │  │         └─ No role found → Navigate to /welcome (corrupt state)
   │  └─ NO → Navigate to /welcome (not logged in)
   └─ End
```

## Implementation Details

### 1. Auth State Service
**File**: `lib/core/services/auth_state_service.dart`

**Purpose**: Manage login state persistence

**Class**: `AuthStateService` (Singleton)

**Methods**:
```dart
// Save login state after successful login
Future<void> saveLoginState({
  required String uid,
  required String email,
  required String role,
})

// Get saved login state
Future<Map<String, String>?> getLoginState()

// Check if user is logged in (quick check)
Future<bool> isLoggedIn()

// Clear login state on logout
Future<void> clearLoginState()

// Get just the role (for quick routing)
Future<String?> getSavedRole()
```

**SharedPreferences Keys**:
- `is_logged_in` → bool
- `user_uid` → String (Firebase UID)
- `user_email` → String
- `user_role` → String ('student', 'proctorial', 'security')
- `last_login_time` → String (ISO8601 format)

### 2. Update SplashScreen
**File**: `lib/presentation/splash/splash_screen.dart`

**Changes**:
```dart
// In Timer callback (after 5 seconds):
1. Check FirebaseAuth.currentUser
2. If null → Navigate to /welcome
3. If not null:
   - Get role from AuthStateService.getSavedRole()
   - If role == 'student' → Navigate to /student-profile
   - If role == 'proctorial' → Navigate to /home (args: 'proctorial body')
   - If role == 'security' → Navigate to /home (args: 'security body')
   - If role == null → Navigate to /welcome (force re-login)
```

### 3. Update Login Success Flow
**File**: `lib/presentation/auth/login_screen.dart`

**In `_submit()` method after successful login**:
```dart
if (success) {
  // Save login state
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await AuthStateService.instance.saveLoginState(
      uid: user.uid,
      email: user.email ?? email,
      role: _role.toLowerCase(),
    );
  }
  
  // Navigate as before
  if (_role == 'Student') {
    Navigator.pushReplacementNamed(context, AppRoutes.studentProfile);
  } else {
    Navigator.pushReplacementNamed(context, AppRoutes.home, arguments: _role.toLowerCase());
  }
}
```

### 4. Update Logout Flow
**File**: `lib/presentation/settings/settings_screen.dart`

**In `_confirmLogout()` method**:
```dart
if (result == true) {
  if (!mounted) return;
  
  // Clear login state
  await AuthStateService.instance.clearLoginState();
  
  // Clear AlertController before logout
  AlertController.instance.logout();
  
  // Sign out from Firebase
  await FirebaseAuth.instance.signOut();
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Logged out'))
  );
  Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
}
```

## Data Structure

### LoginState Model (Stored in SharedPreferences)
```dart
{
  "is_logged_in": true,
  "user_uid": "abc123xyz789",
  "user_email": "student@student.nstu.edu.bd",
  "user_role": "student",
  "last_login_time": "2026-01-09T10:30:00.000Z"
}
```

### Role Mapping
- `"student"` → Navigate to `/student-profile`
- `"proctorial"` → Navigate to `/home` with args `"proctorial body"`
- `"security"` → Navigate to `/home` with args `"security body"`

## Security Considerations

### ✅ Safe Practices
1. **Firebase Auth Token**: Automatically managed by Firebase SDK
2. **SharedPreferences**: Used only for UI routing decisions
3. **Double Check**: Always verify FirebaseAuth.currentUser before trusting SharedPreferences
4. **No Sensitive Data**: Never store passwords or auth tokens

### ⚠️ Important Notes
- SharedPreferences is **not encrypted** on most platforms
- Only store non-sensitive routing information
- Real authentication verified through Firebase
- If Firebase token expires, app will require re-login automatically

## Testing Checklist

### Before Implementation
- [x] Confirm SharedPreferences package installed
- [x] Confirm Firebase Auth working
- [x] Confirm routing structure documented

### After Implementation
- [x] Implementation complete - all files updated
- [ ] Fresh install → Login → Close app → Reopen → Should stay logged in
- [ ] Student login → Restart → Should go to StudentProfile
- [ ] Proctorial login → Restart → Should go to Home (proctorial view)
- [ ] Security login → Restart → Should go to Home (security view)
- [ ] Logout → Restart → Should go to Welcome screen
- [ ] Clear app data → Should go to Welcome screen
- [ ] Firebase token expires → Should prompt re-login

## Files to Create/Modify

### Create New:
1. `lib/core/services/auth_state_service.dart` (New service)

### Modify Existing:
1. `lib/presentation/splash/splash_screen.dart` (Add auth check)
2. `lib/presentation/auth/login_screen.dart` (Save login state)
3. `lib/presentation/settings/settings_screen.dart` (Clear login state)

## Implementation Order

1. ✅ Create plan documentation (this file)
2. ✅ Create `AuthStateService` with all methods
3. ✅ Update `SplashScreen` with auth check logic
4. ✅ Update `LoginScreen` to save login state
5. ✅ Update `SettingsScreen` logout to clear state
6. ⏳ Test all scenarios

## Notes for Future Reference

- **Pattern**: Check Firebase first, then SharedPreferences for routing
- **Fallback**: Always default to welcome screen if state is unclear
- **Role Format**: Store lowercase ('student', 'proctorial', 'security')
- **Navigation**: Use `pushReplacementNamed` to clear navigation stack
- **Logout**: Clear both Firebase auth AND SharedPreferences

---

**Created**:✅ Implementation Complete - Ready for Testing  
**Last Updated**: 2026-01-09
**Status**: Planning Complete, Ready for Implementation
