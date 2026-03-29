# SMS to Multiple Proctors - Implementation Plan

## Current State

**File:** `lib/core/services/sms_escalation_service.dart`

**Current Implementation (Lines 144-146):**
```dart
final List<String> testPhones = [
  '+8801714721112',
  '+8801835498205',
];
```
- ✅ Sends SMS to 2 hardcoded numbers
- ❌ Requires manual updates when proctors change
- ❌ No dynamic scaling

---

## Goal

**Fetch all proctor phone numbers from Firestore automatically** and send SMS to every proctor in the database.

---

## Database Structure

### Collection: `users`
```json
{
  "uid": "abc123",
  "name": "Dr. Ahmed",
  "role": "proctorial",
  "phone": "+8801712345678",  // ← Extract this
  "email": "ahmed@nstu.edu.bd",
  "designation": "assistant proctor",  // ← Filter by this
  "department": "Proctorial Body"
}
```

**Designation values in database:**
- `proctor` - Chief Proctor
- `assistant proctor` - Assistant Proctors
- `student` - Students (no designation)
- `security` - Security Staff

---

## Implementation Steps

### Step 1: Query Firestore for Proctorial Users

**Replace:** Lines 144-156 (hardcoded test phones section)

**With:**
```dart
// Fallback phone numbers (hardcoded)
final List<String> testPhones = [
  '+8801714721112',
  '+8801835498205',
];

List<String> proctorPhones = [];

try {
  // Fetch all proctor and assistant proctor phone numbers from Firestore
  final proctorsSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('designation', whereIn: ['Proctor', 'Assistant Proctor'])
      .get();

  // Extract phone numbers
  for (final doc in proctorsSnapshot.docs) {
    final phone = doc.data()['phone'] as String?;
    if (phone != null && phone.isNotEmpty) {
      proctorPhones.add(phone);
    }
  }

  if (proctorPhones.isNotEmpty) {
    print('📱 Found ${proctorPhones.length} proctor phone numbers from database');
  } else {
    print('⚠️ No proctors found in database - using fallback phones');
    proctorPhones = testPhones;
  }
} catch (e) {
  print('❌ Firestore query failed: $e - using fallback phones');
  proctorPhones = testPhones;
}
```

---

### Step 2: Validate Phone Numbers

**Add validation before sending:**
```dart
bool _isValidBDPhone(String phone) {
  // Bangladesh phone format: +880XXXXXXXXXX
  if (!phone.startsWith('+880')) return false;
  
  // Check if remaining digits are numeric (after +880)
  final digits = phone.substring(4);
  return int.tryParse(digits) != null && digits.length >= 10;
}

// Filter valid phones
final validPhones = proctorPhones
    .where((phone) => _isValidBDPhone(phone))
    .toList();

print('✅ ${validPhones.length} valid phone numbers');
```

---

### Step 3: Send SMS to All Proctors

**Replace:** Lines 190-213 (loop through testPhones)

**With:**
```dart
int smsSent = 0;
int smsFailed = 0;

// validPhones will contain either database phones or fallback testPhones
for (final phone in validPhones) {
  try {
    print('📤 Sending SMS to $phone...');

    // Native SMS (silent, no user interaction)
    final success = await NativeSms.sendSMS(
      phone: phone,
      message: smsBody,
    );

    if (success) {
      smsSent++;
      print('✅ SMS sent to $phone');
    } else {
      smsFailed++;
      print('❌ SMS failed for $phone');
    }

    // Rate limiting: 500ms delay between messages
    await Future.delayed(Duration(milliseconds: 500));
  } catch (e) {
    smsFailed++;
    print('❌ Error sending SMS to $phone: $e');
  }
}

print('📊 SMS Report: $smsSent sent, $smsFailed failed');
```

---

### Step 4: Update Firestore Alert Status

**Update:** Lines 249-255 (Firestore update)

**Add SMS recipient details:**
```dart
await FirebaseFirestore.instance
    .collection('proctorial_alerts')
    .doc(alertId)
    .update({
      'smsEscalated': true,
      'smsEscalatedAt': FieldValue.serverTimestamp(),
      'smsCount': smsSent,
      'smsFailedCount': smsFailed,
      'smsRecipients': validPhones,  // ← Add this
    });
```

---

## Error Handling

### Scenario 1: No Proctors in Database
```dart
// Already handled in Step 1 with fallback logic
if (proctorPhones.isEmpty) {
  print('⚠️ No proctors found in database - using fallback');
  proctorPhones = testPhones;  // Use hardcoded test phones
}

// SMS will be sent to testPhones automatically
print('📱 Using ${proctorPhones.length} phone numbers');
```

### Scenario 2: All Phone Numbers Invalid
```dart
if (validPhones.isEmpty) {
  print('❌ No valid phone numbers found (even after validation)');
  
  // This should not happen since testPhones are always valid
  // But if it does, use emergency fallback
  validPhones = ['+8801714721112'];  // Single emergency contact
  
  // Log error to Firestore
  await FirebaseFirestore.instance
      .collection('system_logs')
      .add({
        'type': 'SMS_ESCALATION_WARNING',
        'alertId': alertId,
        'reason': 'All phone numbers invalid - using emergency fallback',
        'timestamp': FieldValue.serverTimestamp(),
      });
}
```

### Scenario 3: SMS Permission Denied
```dart
try {
  final success = await NativeSms.sendSMS(...);
} catch (e) {
  if (e.toString().contains('PERMISSION_DENIED')) {
    print('❌ SMS permission denied by user');
    
    // Fallback: Open SMS composer
    final Uri smsUri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(smsBody)}');
    await launchUrl(smsUri, mode: LaunchMode.externalApplication);
  }
}
```

---

## Testing Strategy

### Test 1: Single Proctor
```dart
// Add one proctor to Firestore
{
  "designation": "proctor",
  "phone": "+8801712345678"
}

// Expected: 1 SMS sent
```

### Test 2: Multiple Proctors
```dart
// Add 5 proctors with valid phones
// Expected: 5 SMS sent with 500ms intervals
```

### Test 3: Invalid Phone Numbers
```dart
// Add proctors with:
// - Missing '+880' prefix
// - Wrong length
// - Empty phone field

// Expected: Skipped with warnings in console
```

### Test 4: Mixed Valid/Invalid
```dart
// 3 valid + 2 invalid phones
// Expected: 3 SMS sent, 2 skipped
```

### Test 5: Database Empty
```dart
// No users with designation='proctor' or 'assistant proctor'
// Expected: Fallback to testPhones
```

---

## Performance Considerations

| Metric | Value | Optimization |
|--------|-------|--------------|
| **Database Query** | 1 query | ✅ Single where clause |
| **SMS Send Time** | ~500ms each | 500ms delay = rate limiting |
| **Total Time (5 proctors)** | ~2.5 seconds | Acceptable |
| **Total Time (20 proctors)** | ~10 seconds | Consider parallel sending |
| **Network Errors** | Retry 3 times | Implement retry logic |
| **Firestore Reads** | 1 read per proctor | Cached for 5 minutes |

### Optimization: Parallel SMS Sending
```dart
// For large proctor lists (>10), send in batches
const int batchSize = 5;
for (int i = 0; i < validPhones.length; i += batchSize) {
  final batch = validPhones.skip(i).take(batchSize);
  
  await Future.wait(
    batch.map((phone) => NativeSms.sendSMS(phone: phone, message: smsBody))
  );
  
  await Future.delayed(Duration(seconds: 1)); // Between batches
}
```

---

## Security Considerations

### 1. Phone Number Privacy
```dart
// Don't log full phone numbers in production
print('📤 Sending SMS to ${phone.substring(0, 7)}***');
```

### 2. Rate Limiting
```dart
// Prevent SMS spam
final lastSmsTime = await _getLastSmsTime(alertId);
if (DateTime.now().difference(lastSmsTime) < Duration(minutes: 5)) {
  print('⚠️ SMS sent too recently - skipping');
  return;
}
```

### 3. Permission Check
```dart
// Check SMS permission before sending
final status = await Permission.sms.status;
if (!status.isGranted) {
  await Permission.sms.request();
}
```

---

## Code Changes Summary

### File: `lib/core/services/sms_escalation_service.dart`

**Lines to Modify:**
1. **Lines 144-156**: Replace hardcoded testPhones with Firestore query
2. **Lines 190-213**: Update SMS sending loop to use fetched phones
3. **Lines 249-255**: Add SMS recipient details to Firestore update
4. **Add new method**: `_isValidBDPhone()` for phone validation

**Lines to Delete:**
- Lines 217-246: Remove commented TODO section (no longer needed)

**Estimated Changes:**
- 40 lines replaced
- 20 lines added (validation logic)
- 30 lines deleted (TODO comments)
- **Net change:** +30 lines

---

## Rollback Plan

**Built-in Fallback:** The implementation already includes automatic fallback to `testPhones` in two scenarios:

1. **Firestore Query Fails** (network error, permission denied, etc.)
   - Catches exception and uses testPhones
   - Logs error to console
   - SMS still sent successfully

2. **Database Returns Empty** (no proctors registered)
   - Checks if `proctorPhones.isEmpty`
   - Falls back to testPhones
   - Logs warning to console

**Emergency Rollback:** If the entire feature needs to be disabled:
```dart
// Comment out lines 144-180 (Firestore query)
// Keep only:
final List<String> proctorPhones = [
  '+8801714721112',
  '+8801835498205',
];
// SMS sending code remains unchanged
```

This reverts to the original hardcoded behavior with zero downtime.

---

## Future Enhancements

### 1. SMS Templates
```dart
enum SmsTemplate {
  EMERGENCY,
  RESOLVED,
  FOLLOWUP,
}

String _getSmsBody(SmsTemplate template, Map<String, dynamic> data) {
  switch (template) {
    case SmsTemplate.EMERGENCY:
      return 'EMERGENCY: ${data['studentName']} at ${data['location']}';
    // ...
  }
}
```

### 2. SMS History Tracking
```dart
// Save SMS history to Firestore
await FirebaseFirestore.instance
    .collection('sms_history')
    .add({
      'alertId': alertId,
      'recipients': validPhones,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'success',
    });
```

### 3. Multiple Recipient Groups
```dart
// Send to proctors AND security staff
final staffSnapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('designation', whereIn: ['proctor', 'assistant proctor', 'security officer'])
    .get();

// Or use role field for broader groups
// .where('role', whereIn: ['proctorial', 'security'])
```

### 4. SMS Delivery Status
```dart
// Track SMS delivery (requires SMS gateway integration)
await _trackSmsDelivery(phone, messageId);
```

---

## Implementation Checklist

- [ ] Add phone validation method `_isValidBDPhone()`
- [ ] Replace testPhones with Firestore query
- [ ] Update SMS sending loop for dynamic phone list
- [ ] Add error handling for empty database
- [ ] Update Firestore alert status with recipient list
- [ ] Test with 1 proctor
- [ ] Test with 5 proctors
- [ ] Test with invalid phone numbers
- [ ] Test with empty database
- [ ] Test SMS permission denied scenario
- [ ] Remove hardcoded TODO comments
- [ ] Add logging for debugging
- [ ] Deploy and monitor

---

## Expected Outcome

### Before (Hardcoded):
```
📤 Sending SMS to +8801714721112...
✅ SMS sent
📤 Sending SMS to +8801835498205...
✅ SMS sent
📊 SMS Report: 2 sent, 0 failed
```

### After (Dynamic - Success Case):
```
📱 Found 8 proctor phone numbers from database (designation: proctor/assistant proctor)
✅ 8 valid phone numbers
📤 Sending SMS to +880171***...
✅ SMS sent
📤 Sending SMS to +880183***...
✅ SMS sent
... (6 more)
📊 SMS Report: 8 sent, 0 failed
📝 Updated Firestore: smsRecipients = [+880..., +880..., ...]
```

### After (Dynamic - Fallback Case):
```
⚠️ No proctors found in database - using fallback phones
✅ 2 valid phone numbers
📤 Sending SMS to +880171***...
✅ SMS sent
📤 Sending SMS to +880183***...
✅ SMS sent
📊 SMS Report: 2 sent, 0 failed
📝 Updated Firestore: smsRecipients = [+8801714721112, +8801835498205]
```

---

## Timeline

| Task | Estimated Time |
|------|----------------|
| Add phone validation | 10 minutes |
| Update Firestore query | 15 minutes |
| Update SMS loop | 10 minutes |
| Add error handling | 15 minutes |
| Testing (all scenarios) | 30 minutes |
| Code cleanup | 10 minutes |
| **Total** | **90 minutes** |

---

## Next Steps

1. Review this plan
2. Confirm database structure matches expectations
3. Implement changes to `sms_escalation_service.dart`
4. Test with real Firebase database
5. Monitor SMS delivery success rate

Ready to proceed with implementation?
