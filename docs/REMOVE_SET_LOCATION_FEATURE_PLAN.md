# Remove "Set Location" Feature - Implementation Plan

## Overview
Remove the "Set Location" feature entirely and rely **only on real-time GPS location** for all emergency alerts. When sending an alert, the app will capture the current real-time latitude and longitude and send it to proctors who can view it on Google Maps.

---

## Current State Analysis

### ✅ What Exists Now

#### 1. **Set Location Feature (TO BE REMOVED)**
- **Location**: `lib/presentation/home/student_profile_screen.dart`
- **UI Components**:
  - "Set Location" button in student profile (lines 1181-1299)
  - Building selection dialog (lines 210-282)
  - Floor selection dialog (lines 283-340)
  - Pre-defined building list with coordinates (lines 48-73)
  
- **Backend Storage**: `lib/presentation/auth/controllers/profile_controller.dart`
  - `savedLocation` field (line 16)
  - `latitude` field (line 17)
  - `longitude` field (line 18)
  - `building` field (line 19)
  - `floor` field (line 20)
  - `setLocation()` method (lines 46-62)
  - SharedPreferences storage (lines 90, 152)

#### 2. **Real-Time Location System (KEEP & USE)**
- **Already Working Correctly**:
  - Shake alert gets real-time GPS (`shake_detection_service.dart`, lines 136-158)
  - Volume button SOS gets real-time GPS (`volume_button_sos_service.dart`, lines 214-241)
  - Manual SOS button gets real-time GPS (`student_profile_screen.dart`, lines 546-562)
  - All use `Geolocator.getCurrentPosition()` with `LocationAccuracy.bestForNavigation`

#### 3. **Map Viewing for Proctors (WORKING)**
- **alert_details_page.dart** (lines 18-47):
  - Fetches `liveLatitude`/`liveLongitude` or falls back to `latitude`/`longitude`
  - Opens Google Maps with real-time coordinates
  - URL: `https://www.google.com/maps/search/?api=1&query=$lat,$lon`

- **Web Dashboard** (`web/proctorial_dashboard.html`, lines 509-516):
  - "🗺️ View on Map" button
  - `openMap(lat, lon)` function (lines 567-569)
  - Opens Google Maps in new tab

---

## Problem Statement

### ❌ Issues with Current "Set Location" Feature
1. **Confusing UX**: Students can set a building/floor manually, but alerts still capture real-time GPS
2. **Outdated Data**: Saved location becomes stale if student moves to a different building
3. **Unnecessary Complexity**: Pre-defined building coordinates don't match actual student position
4. **Redundant**: All alert triggers (shake, volume, manual SOS) already use real-time GPS
5. **Inconsistent**: Student profile shows "Set Location" button but alert uses real GPS anyway

### ✅ Solution
- **Remove** all "Set Location" UI and storage
- **Keep** real-time GPS capture for all alerts
- **Simplify** student profile to only show current real-time location
- **Keep** Google Maps viewing for proctors (already uses real-time coordinates)

---

## Implementation Plan

### Phase 1: Remove UI Components

#### File: `lib/presentation/home/student_profile_screen.dart`

**1. Remove Building/Floor Selection UI**
- **Lines 48-73**: Delete `_buildingNames` list and `_buildingCoordinates` map
- **Lines 210-340**: Delete `_showBuildingFloorSelection()` method
- **Lines 352-389**: Delete `_saveSelectedLocation()` method
- **Lines 1181-1299**: Delete "Set Location" button case in `_buildActionButton()`

**2. Update Location Display**
- **Lines 195-207**: Simplify `_initializeLocation()` to only show "Finding location..."
- Remove dependency on `ProfileController.instance.savedLocation`
- Update to display "Real-time GPS tracking active" or similar

**3. Update SOS Alert Logic**
- **Lines 542-607**: No changes needed - already uses real-time GPS
- **Lines 649-687**: Live location updates - no changes needed (already real-time)
- Keep reverse geocoding logic (lines 690-710)

#### File: `lib/presentation/home/map_screen.dart`

**1. Simplify Map Initialization**
- **Lines 14-16**: Remove `latitude` and `longitude` parameters from constructor
- **Lines 44-96**: Keep `_getCurrentLocation()` - already uses real-time GPS only
- Remove fallback to saved location (lines 67-87)
- Keep NSTU campus fallback for permission denied cases

**2. Update Marker Display**
- **Lines 99-120**: Keep marker logic (already shows current location)
- **Lines 603-604**: Update marker title to always say "Current Location"

---

### Phase 2: Remove Backend Storage

#### File: `lib/presentation/auth/controllers/profile_controller.dart`

**1. Remove Fields**
```dart
// DELETE these lines (16-20):
String? savedLocation;
double? latitude;
double? longitude;
String? building;
String? floor;
```

**2. Remove Methods**
```dart
// DELETE setLocation() method (lines 46-62):
void setLocation({
  required String location,
  required double lat,
  required double lon,
  String? building,
  String? floor,
}) { ... }
```

**3. Update SharedPreferences**
```dart
// DELETE from loadFromPrefs() (line 90):
savedLocation = prefs.getString('profile.savedLocation');
latitude = prefs.getDouble('profile.latitude');
longitude = prefs.getDouble('profile.longitude');

// DELETE from _saveToPrefs() (lines 150-152):
if (savedLocation != null) await prefs.setString('profile.savedLocation', savedLocation!);
if (latitude != null) await prefs.setDouble('profile.latitude', latitude!);
if (longitude != null) await prefs.setDouble('profile.longitude', longitude!);
```

---

### Phase 3: Update Alert Flow (Minimal Changes)

#### File: `lib/presentation/home/student_profile_screen.dart`

**1. Update SOS Alert Method**
```dart
// Lines 542-607: Update to remove references to saved location
// BEFORE:
latitude = profileController.latitude ?? 0.0;
longitude = profileController.longitude ?? 0.0;

// AFTER:
double latitude = 0.0;
double longitude = 0.0;
```

**2. Remove Building/Floor from Alerts**
```dart
// Lines 573-580: Remove building and floor parameters
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
  // DELETE these two lines:
  building: _selectedBuilding,
  floor: _selectedFloor,
);
```

**3. Remove Building/Floor from Live Updates**
```dart
// Lines 589-596: Remove building and floor from Firestore update
await FirebaseFirestore.instance
  .collection('proctorial_alerts')
  .doc(alertId)
  .update({
    'liveLatitude': latitude,
    'liveLongitude': longitude,
    'liveLocationName': locString,
    // DELETE these two lines:
    'building': _selectedBuilding,
    'floor': _selectedFloor,
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

---

### Phase 4: Update Shake & Volume Services (Minimal)

#### File: `lib/core/services/shake_detection_service.dart`

**No changes needed** - Lines 136-195 already use real-time GPS correctly.
- ✅ Gets `Geolocator.getCurrentPosition()`
- ✅ Falls back to stored values only if GPS fails
- ✅ Reverse geocodes for human-readable location

#### File: `lib/core/services/volume_button_sos_service.dart`

**No changes needed** - Lines 214-265 already use real-time GPS correctly.
- ✅ Gets `Geolocator.getCurrentPosition()`
- ✅ Falls back to stored values only if GPS fails
- ✅ Reverse geocodes for human-readable location

---

### Phase 5: Keep Map Viewing (No Changes)

#### File: `lib/presentation/home/alert_details_page.dart`

**✅ Keep as-is** - Already works correctly:
- Lines 18-47: Fetches real-time `liveLatitude`/`liveLongitude`
- Opens Google Maps with real-time coordinates
- Perfect for proctors to track students

#### File: `web/proctorial_dashboard.html`

**✅ Keep as-is** - Already works correctly:
- Lines 509-516: "View on Map" button
- Lines 567-569: Opens Google Maps with lat/lon
- No changes needed

---

## Data Flow After Changes

### Student Sends Alert:
```
1. Student triggers alert (manual/shake/volume)
   ↓
2. App gets current GPS: Geolocator.getCurrentPosition()
   ↓
3. Reverse geocode to human-readable address (optional)
   ↓
4. Send to Firebase: { latitude, longitude, location, ... }
   ↓
5. Live location updates stream to Firebase every ~10 meters
```

### Proctor Views Alert:
```
1. Proctor sees alert in dashboard
   ↓
2. Clicks "View on Map" button
   ↓
3. Opens Google Maps with: latitude & longitude
   ↓
4. Google Maps shows exact student location
```

---

## Testing Checklist

### Before Implementation
- [x] Confirm all alert types use real-time GPS
- [x] Confirm map viewing works with real-time coordinates
- [x] Confirm live location updates work correctly

### After Implementation
- [ ] Remove "Set Location" button from student profile
- [ ] Remove building/floor selection dialogs
- [ ] Remove saved location from ProfileController
- [ ] Remove saved location from SharedPreferences
- [ ] Test manual SOS - should use real-time GPS ✓
- [ ] Test shake alert - should use real-time GPS ✓
- [ ] Test volume button SOS - should use real-time GPS ✓
- [ ] Test proctor "View Map" - should open Google Maps correctly ✓
- [ ] Test live location updates - should stream to Firebase ✓
- [ ] Verify no references to building/floor in alerts

---

## Files to Modify

### UI Layer (Remove Set Location)
1. ✏️ `lib/presentation/home/student_profile_screen.dart`
   - Delete building/floor selection UI (lines 48-73, 210-340, 352-389, 1181-1299)
   - Update location display to show real-time only
   - Remove building/floor from alert calls

2. ✏️ `lib/presentation/home/map_screen.dart`
   - Remove saved location parameters
   - Simplify to only use real-time GPS

### Backend Layer (Remove Storage)
3. ✏️ `lib/presentation/auth/controllers/profile_controller.dart`
   - Delete savedLocation, latitude, longitude, building, floor fields
   - Delete setLocation() method
   - Remove from SharedPreferences load/save

### No Changes Needed (Already Correct)
4. ✅ `lib/core/services/shake_detection_service.dart` - Uses real-time GPS
5. ✅ `lib/core/services/volume_button_sos_service.dart` - Uses real-time GPS
6. ✅ `lib/presentation/home/alert_details_page.dart` - Uses real-time coordinates
7. ✅ `web/proctorial_dashboard.html` - Uses real-time coordinates
8. ✅ `lib/data/services/alert_service.dart` - Just sends data as-is
9. ✅ `functions/index.js` - Just receives and stores data

---

## Security & Privacy Considerations

### ✅ Advantages of Real-Time GPS Only
1. **Accurate Location**: Always shows where student actually is
2. **Privacy**: No persistent location storage in SharedPreferences
3. **Live Tracking**: Proctors can see if student is moving
4. **Simple**: Less code, fewer bugs, clearer UX

### ⚠️ Important Notes
- Real-time GPS requires location permission (already handled)
- Falls back to NSTU campus coordinates if permission denied
- Reverse geocoding provides human-readable address
- Google Maps viewing doesn't expose raw coordinates to UI

---

## Migration Notes

### For Existing Users
- **No data migration needed** - saved locations will simply stop being used
- **No breaking changes** - app will work immediately after update
- **Better UX** - students see their actual location, not outdated saved location

### For Proctors
- **No changes needed** - "View Map" button continues to work
- **More accurate** - shows where student actually is, not where they said they were

---

## Documentation Updates

### Update These Docs:
1. `docs/SafeLink_NSTU_Project_Documentation.md`
   - Remove FR9 "Pre-Set Danger Location" requirement
   - Update FR7 to only mention real-time GPS
   - Remove building/floor selection from workflows

2. `README.md` (if exists)
   - Remove mention of "set location" feature
   - Emphasize real-time GPS tracking

---

## Implementation Order

1. ✅ Create this plan document
2. ⏳ Remove UI components from student_profile_screen.dart
3. ⏳ Remove backend storage from profile_controller.dart
4. ⏳ Update map_screen.dart to remove saved location fallback
5. ⏳ Update alert calls to remove building/floor parameters
6. ⏳ Test all alert types (manual, shake, volume)
7. ⏳ Test proctor map viewing
8. ⏳ Update documentation

---

**Created**: 2026-01-09  
**Status**: Planning Complete - Ready for Implementation  
**Priority**: High - Simplifies UX and improves location accuracy
