import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController extends ChangeNotifier {
  static final ProfileController instance = ProfileController._internal();
  ProfileController._internal();

  String name = 'Student';
  String studentId = 'CSE-2019-0001';
  String department = 'Computer Science & Engineering';
  String session = '2019-20';
  String phone = '01819129553';
  String email = 'student@nstu.edu.bd';

  // Staff-specific fields
  String designation = '';
  String role = 'student';

  // Pulse location fields
  String pulseBuilding = '';
  String pulseFloor = '';
  String pulseRoom = '';
  String pulseMessage = '';

  void setSignupEmail(String value) {
    email = value;
    notifyListeners();
  }

  /// Quick synchronous check of saved role from SharedPreferences
  /// Used for rapid role detection during app initialization
  static Future<String> quickGetRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('profile.role') ?? 'student';
    } catch (e) {
      debugPrint('⚠️ Error quick loading role: $e');
      return 'student';
    }
  }

  /// Synchronously load role from SharedPreferences cache
  /// Note: This may load stale data if SharedPreferences instance isn't initialized yet
  void loadRoleSync() {
    try {
      // Try to get the instance synchronously from cache if available
      // This is a workaround since SharedPreferences.getInstance() is async
      role = 'student'; // Default fallback
      debugPrint('ℹ️ Role loaded synchronously (fallback to default)');
    } catch (e) {
      debugPrint('⚠️ Error in loadRoleSync: $e');
    }
  }

  void setProfileSetup({
    required String name,
    required String studentId,
    required String department,
    required String session,
    required String phone,
  }) {
    this.name = name;
    this.studentId = studentId;
    this.department = department;
    this.session = session;
    this.phone = phone;
    notifyListeners();
  }

  Future<void> updateAll({
    String? name,
    String? studentId,
    String? department,
    String? session,
    String? phone,
    String? email,
  }) async {
    if (name != null) this.name = name;
    if (studentId != null) this.studentId = studentId;
    if (department != null) this.department = department;
    if (session != null) this.session = session;
    if (phone != null) this.phone = phone;
    if (email != null) this.email = email;
    notifyListeners();
    await _saveToPrefs();
    await _saveToFirestore();
  }

  Future<void> setPulseLocation({
    required String building,
    required String floor,
    required String room,
    String message = '',
  }) async {
    pulseBuilding = building;
    pulseFloor = floor;
    pulseRoom = room;
    pulseMessage = message;
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> clearPulseLocation() async {
    pulseBuilding = '';
    pulseFloor = '';
    pulseRoom = '';
    pulseMessage = '';
    notifyListeners();
    await _saveToPrefs();
  }

  /// Save updated profile to Firestore
  Future<void> _saveToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updateData = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
      };

      // Add student-specific fields if role is student
      if (role == 'student') {
        updateData['studentId'] = studentId;
        updateData['department'] = department;
        updateData['session'] = session;
      }
      // Add staff-specific fields if role is proctorial or security
      else if (role == 'proctorial' || role == 'security') {
        updateData['designation'] = designation;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      debugPrint('✅ Profile saved to Firestore successfully');
    } catch (e) {
      debugPrint('❌ Error saving profile to Firestore: $e');
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString('profile.name') ?? name;
    studentId = prefs.getString('profile.studentId') ?? studentId;
    department = prefs.getString('profile.department') ?? department;
    session = prefs.getString('profile.session') ?? session;
    phone = prefs.getString('profile.phone') ?? phone;
    email = prefs.getString('profile.email') ?? email;
    designation = prefs.getString('profile.designation') ?? designation;
    role = prefs.getString('profile.role') ?? role;
    pulseBuilding = prefs.getString('profile.pulseBuilding') ?? '';
    pulseFloor = prefs.getString('profile.pulseFloor') ?? '';
    pulseRoom = prefs.getString('profile.pulseRoom') ?? '';
    pulseMessage = prefs.getString('profile.pulseMessage') ?? '';
    notifyListeners();
  }

  /// Load user profile from Firestore (works for all roles including staff)
  Future<void> loadFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No Firebase user, skipping Firestore load');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ User document not found in Firestore');
        return;
      }

      final data = doc.data()!;

      // Common fields
      name = data['name'] ?? name;
      email = data['email'] ?? email;
      phone = data['phone'] ?? phone;
      role = data['role'] ?? role;

      debugPrint(
        '✅ Profile loaded from Firestore - Role: $role, Name: $name, Email: $email',
      );

      // Staff-specific fields
      if (role == 'proctorial' || role == 'security') {
        designation = data['designation'] ?? '';
        // Clear student-specific fields for staff
        studentId = '';
        session = '';
        if (role == 'proctorial') {
          department = 'Proctorial Body';
        } else {
          department = 'Security Body';
        }
      } else {
        // Student-specific fields
        studentId = data['studentId'] ?? studentId;
        department = data['department'] ?? department;
        session = data['session'] ?? session;
      }

      notifyListeners();
      await _saveToPrefs();
    } catch (e) {
      debugPrint('❌ Error loading profile from Firestore: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile.name', name);
    await prefs.setString('profile.studentId', studentId);
    await prefs.setString('profile.department', department);
    await prefs.setString('profile.session', session);
    await prefs.setString('profile.phone', phone);
    await prefs.setString('profile.email', email);
    await prefs.setString('profile.designation', designation);
    await prefs.setString('profile.role', role);
    await prefs.setString('profile.pulseBuilding', pulseBuilding);
    await prefs.setString('profile.pulseFloor', pulseFloor);
    await prefs.setString('profile.pulseRoom', pulseRoom);
    await prefs.setString('profile.pulseMessage', pulseMessage);
  }
}
