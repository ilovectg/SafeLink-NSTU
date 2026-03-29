import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import './profile_controller.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  /// Sign in and optionally restrict to specified roles (e.g. ['student'], ['proctorial']).
  Future<bool> login(
    String email,
    String password, {
    List<String>? allowedRoles,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      debugPrint('[Auth] Attempting login for: $email');
      
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = cred.user?.uid;
      if (uid == null) {
        debugPrint('[Auth] Login failed: No UID returned');
        isLoading = false;
        notifyListeners();
        return false;
      }
      
      debugPrint('[Auth] Login successful, UID: $uid');
      
      if (allowedRoles != null) {
        debugPrint('[Auth] Checking role authorization...');
        final doc = await _firestore.collection('users').doc(uid).get();
        final role = doc.data()?['role'] as String?;
        debugPrint('[Auth] User role: $role, Allowed: $allowedRoles');
        
        if (role == null || !allowedRoles.contains(role)) {
          // Not authorized for the selected role — immediately sign out
          debugPrint('[Auth] Role mismatch - signing out');
          await _auth.signOut();
          isLoading = false;
          notifyListeners();
          return false;
        }
      }
      
      // Load user profile from Firestore after successful login
      debugPrint('[Auth] Loading user profile...');
      await ProfileController.instance.loadFromFirestore();
      
      isLoading = false;
      notifyListeners();
      debugPrint('[Auth] Login process completed successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('[Auth] FirebaseAuthException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('[Auth] Unexpected error during login: $e');
      return false;
    }
  }

  /// Create user account and send email verification. Used during signup flow.
  Future<User?> createUserWithEmailVerification(
    String email,
    String password,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      debugPrint('[Auth] Starting signup for: $email');
      
      // Enforce student institutional domain for signups
      if (!email.toLowerCase().endsWith('@student.nstu.edu.bd')) {
        debugPrint('[Auth] Sign up failed: email domain not allowed: $email');
        isLoading = false;
        notifyListeners();
        return null;
      }

      debugPrint('[Auth] Creating user account...');
      // Create the user account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;

      if (user != null && !user.emailVerified) {
        // Send verification email
        debugPrint('[Auth] Sending verification email...');
        await user.sendEmailVerification();
        debugPrint('[Auth] Email verification sent to $email');
      }

      isLoading = false;
      notifyListeners();
      debugPrint('[Auth] Account created successfully');
      return user;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('[Auth] FirebaseAuthException during signup: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('[Auth] Unexpected error during signup: $e');
      return null;
    }
  }

  /// Complete signup with profile fields. Requires that the user's email has been verified.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String department,
    required String session,
    required String phone,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      // Verify the user is logged in and email is verified
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Reload user to get latest email verification status
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        debugPrint('Email not verified for ${user.email}');
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Save user profile to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'studentId': studentId,
        'department': department,
        'session': session,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'student',
      });

      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Sign up error: $e');
      return false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('Sign up unexpected error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('resetPassword error: $e');
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    isLoading = true;
    notifyListeners();
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      isLoading = false;
      notifyListeners();
      return false;
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      notifyListeners();
      debugPrint('changePassword error: $e');
      return false;
    }
  }
}
