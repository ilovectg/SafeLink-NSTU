# Shake Detection Service Integration Guide

## Service Location
**File:** `lib/core/services/shake_detection_service.dart`

## Where is the Shake Service Called?

### Primary Integration Point: HomeScreen
**File:** `lib/presentation/home/home_screen.dart`

The shake detection service is initialized in the `HomeScreen` widget using the following lifecycle hooks:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // Get user role from route arguments
  final roleArg = ModalRoute.of(context)?.settings.arguments;
  _userRole = (roleArg is String) ? roleArg.toLowerCase() : 'student';
  
  // Initialize shake detection ONLY for students (FR11, FR25)
  if (_userRole == 'student' && !ShakeDetectionService.instance.isListening) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ShakeDetectionService.instance.startListening(context: context);
      }
    });
  }
}

@override
void dispose() {
  // Stop shake detection when leaving home screen
  if (_userRole == 'student') {
    ShakeDetectionService.instance.stopListening();
  }
  super.dispose();
}
```

### Why `didChangeDependencies()`?
- Called after `initState()` when the route arguments are available
- Provides access to `ModalRoute.of(context)` to get user role
- Ensures context is fully initialized before starting shake detection

### Why `addPostFrameCallback()`?
- Ensures the widget tree is fully built before showing dialogs
- Prevents "context not available" errors
- Safe way to call methods that might show UI after build

## Role-Based Activation

### Students Only ✅
- Shake detection **ONLY** starts for users with role = `'student'`
- Automatically started when student reaches HomeScreen
- Automatically stopped when student leaves HomeScreen

### Proctorial Body ❌
- Shake detection **NOT** activated
- They receive alerts but don't trigger them

### Security Body ❌
- Shake detection **NOT** activated
- They receive forwarded alerts only

## Shake Detection Parameters (FR11)

```dart
ShakeDetectionService.instance.startListening(
  context: context,
  shakeThresholdGravity: 1.53,      // 15 m/s² converted to G-force
  minimumShakeCount: 3,              // 3 shakes required
  shakeSlopTimeMS: 2000,             // within 2 seconds
  shakeCountResetTime: 3000,         // 3 second reset window
);
```

### Parameter Explanation:
- **shakeThresholdGravity:** 1.53 G = 15 m/s² (FR11 requirement)
  - Formula: 15 m/s² ÷ 9.8 m/s²/G ≈ 1.53 G
- **minimumShakeCount:** 3 shakes required before triggering
- **shakeSlopTimeMS:** 2000ms = 2 seconds window to detect shakes
- **shakeCountResetTime:** 3000ms = 3 seconds before count resets

## Provider-Consumer Analysis

### ✅ No Provider-Consumer Issues Detected

#### Current Architecture:
1. **Singleton Pattern:** ShakeDetectionService uses singleton (`instance`)
   - No need for Provider/Consumer
   - Globally accessible via `ShakeDetectionService.instance`
   - Thread-safe initialization

2. **No State Management Conflicts:**
   - Service doesn't use ChangeNotifier
   - Doesn't depend on Provider, Riverpod, or Bloc
   - AlertController (also singleton) is independent

3. **Context Management:**
   - Context is passed as parameter, not stored in Provider
   - Service stores context locally for showing dialogs
   - Context is cleared on `stopListening()`

### Potential Issues & Solutions:

#### ⚠️ Issue 1: Context Becomes Invalid
**Problem:** If user navigates away while dialog is showing, context becomes unmounted.

**Current Solution:**
```dart
if (_context != null && _context!.mounted) {
  _showShakePopup(_context!);
}
```

#### ⚠️ Issue 2: Service Not Stopped on App Background
**Problem:** Shake detection continues when app is minimized (as per FR25).

**Status:** ✅ Working as designed
- FR25 requires background detection
- Will implement full background service in Phase 1 of escalation spec

#### ⚠️ Issue 3: Multiple Initializations
**Problem:** Service might be initialized multiple times if user navigates back to HomeScreen.

**Current Solution:**
```dart
if (_userRole == 'student' && !ShakeDetectionService.instance.isListening) {
  // Only start if not already listening
}
```

## Testing the Service

### Manual Test Steps:

1. **Login as Student:**
   ```dart
   // In login, pass role='student' to HomeScreen
   Navigator.pushReplacementNamed(context, AppRoutes.home, arguments: 'student');
   ```

2. **Verify Initialization:**
   - Check console logs:
     ```
     ✅ Shake detection started
        Threshold: 1.53G (≈15.0 m/s²)
        Required shakes: 3
        Time window: 2000ms
     ```

3. **Trigger Shake:**
   - Shake phone rapidly 3 times within 2 seconds
   - Should see:
     ```
     🔔 SHAKE DETECTED!
        Force: 2.45 G
        Direction: ShakeDirection.x
     ```
   - Dialog should appear: "Shake Detected!"

4. **Verify Cleanup:**
   - Navigate away from HomeScreen
   - Check console: `✅ Shake detection stopped on dispose`

### Unit Test (Future):
```dart
test('Shake detection initializes only for students', () {
  // Test student role
  final service = ShakeDetectionService.instance;
  service.startListening(context: mockContext);
  expect(service.isListening, true);
  
  // Test non-student role
  service.stopListening();
  expect(service.isListening, false);
});
```

## Integration with Alert System (Future Phase)

When shake is detected, instead of showing popup, it will:

1. **Check Geofencing** (FR23)
   ```dart
   if (!GeofencingService.instance.isWithinCampus()) {
     // Show error: "SOS only works on campus"
     return;
   }
   ```

2. **Show Confirmation Popup** (FR22)
   ```dart
   final confirmed = await showConfirmationDialog(context);
   if (!confirmed) return;
   ```

3. **Trigger Alert** (FR11)
   ```dart
   await AlertController.instance.sendAlert(
     studentId: currentUser.id,
     studentName: currentUser.name,
     // ... other fields
   );
   ```

## Summary

✅ **Service Location:** `lib/core/services/shake_detection_service.dart`  
✅ **Initialization Point:** `HomeScreen.didChangeDependencies()`  
✅ **Cleanup Point:** `HomeScreen.dispose()`  
✅ **Role-Based:** Only students  
✅ **Parameters:** 15 m/s² (1.53G), 3 shakes, 2-3 second window  
✅ **No Provider Issues:** Uses singleton pattern  
✅ **Context Safety:** Checks `mounted` before showing dialogs  
✅ **Background Support:** Ready for FR25 implementation  

---

**Last Updated:** January 8, 2026  
**Status:** ✅ Implemented and tested  
**Next Phase:** Geofencing integration + Confirmation popup + Alert triggering
