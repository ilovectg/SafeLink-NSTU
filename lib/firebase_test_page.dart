import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseTestPage extends StatefulWidget {
  const FirebaseTestPage({Key? key}) : super(key: key);

  @override
  State<FirebaseTestPage> createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  String _status = '';
  String? _fcmToken;
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();

    // Only setup FCM on Android/iOS; skip on Windows and Web
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _setupMessaging();
      _refreshToken();
    } else {
      debugPrint('FCM not supported on this platform — messaging setup skipped');
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    // Add Windows initialization so desktop notifications work
    final windows = WindowsInitializationSettings(appName: 'SafeLink NSTU', appUserModelId: 'com.example.safelink_n', guid: 'a1b2c3d4-e5f6-7890-abcd-ef0123456789');
    await _localNotifications.initialize(InitializationSettings(android: android, iOS: ios, windows: windows));
  }

  void _setupMessaging() {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'FCM Message';
      final body = message.notification?.body ?? '';
      _showLocalNotification(title, body);
      setState(() => _messages.insert(0, '$title — $body'));
    });

    // Background messages are handled in main.dart's background handler
  }

  Future<void> _refreshToken() async {
    // Only attempt to get a token on supported platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final token = await _messaging.getToken();
      setState(() => _fcmToken = token);
    } else {
      setState(() => _fcmToken = null);
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      setState(() => _status = 'Signing in...');
      final cred = await _auth.signInAnonymously();
      setState(() => _status = 'Signed in: ${cred.user?.uid}');
    } catch (e) {
      setState(() => _status = 'Sign in error: $e');
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    setState(() => _status = 'Signed out');
  }

  Future<void> _writeTestDoc() async {
    try {
      final doc = _firestore.collection('test').doc();
      await doc.set({'createdAt': FieldValue.serverTimestamp(), 'message': 'Hello from app'});
      setState(() => _status = 'Wrote test doc ${doc.id}');
    } catch (e) {
      setState(() => _status = 'Write error: $e');
    }
  }

  Future<void> _readTestDocs() async {
    try {
      final snap = await _firestore.collection('test').orderBy('createdAt', descending: true).limit(10).get();
      final ids = snap.docs.map((d) => d.id).join(', ');
      setState(() => _status = 'Read ${snap.docs.length} docs: $ids');
    } catch (e) {
      setState(() => _status = 'Read error: $e');
    }
  }

  Future<void> _subscribeTopic() async {
    await _messaging.subscribeToTopic('all');
    setState(() => _status = 'Subscribed to topic "all"');
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const android = AndroidNotificationDetails('default_channel', 'Default', importance: Importance.max, priority: Priority.high);
    const ios = DarwinNotificationDetails();
    final windows = WindowsNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios, windows: windows);
    await _localNotifications.show(0, title, body, details);
  }

  Future<void> _callRequestOtp() async {
    try {
      setState(() => _status = 'Calling requestOtp...');
      final callable = FirebaseFunctions.instance.httpsCallable('requestOtp');
      final resp = await callable.call({'email': 'dev@student.nstu.edu.bd', 'purpose': 'signup'});
      setState(() => _status = 'requestOtp response: ${resp.data}');
    } catch (e) {
      setState(() => _status = 'requestOtp error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Test')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(onPressed: _signInAnonymously, child: const Text('Sign in anonymously')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _signOut, child: const Text('Sign out')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _writeTestDoc, child: const Text('Write test doc to Firestore')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _readTestDocs, child: const Text('Read recent test docs')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _subscribeTopic, child: const Text('Subscribe to topic "all"')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _refreshToken, child: const Text('Refresh / Show FCM token')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _callRequestOtp, child: const Text('Test requestOtp (Functions callable)')),
              const SizedBox(height: 16),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_status),
              const SizedBox(height: 12),
              const Text('FCM Token:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SelectableText(_fcmToken ?? 'No token yet'),
              const SizedBox(height: 12),
              const Text('Recent messages:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final m in _messages) Text('• $m'),
              const SizedBox(height: 16),
              // Show desktop notification button on Windows
              if (Platform.isWindows) ...[
                ElevatedButton(onPressed: () => _showLocalNotification('Desktop test', 'This is a Windows notification'), child: const Text('Show desktop notification')),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              if (kDebugMode) ...[
                const Divider(),
                const Text('Debug notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('• Ensure you added native config files (google-services.json / GoogleService-Info.plist).'),
                const SizedBox(height: 4),
                const Text('• To use `DefaultFirebaseOptions`, run `flutterfire configure` and add `firebase_options.dart`.'),
                const SizedBox(height: 4),
                const Text('• To test notifications from server: use FCM send API with the token above or send to topic "all".'),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
