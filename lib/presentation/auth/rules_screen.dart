import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';
// back button widget not used here; removed import

class RulesScreen extends StatelessWidget {
  const RulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.profileSetup),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text('Rules and Policies', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome to SafeLink NSTU, the official app for Noakhali Science and Technology University. By using this app, you agree to comply with and be bound by the following terms and conditions of use.\n\nPlease review these terms carefully. If you do not agree with these terms, you should not use this app.\n\n1. Acceptance of Terms\nBy accessing or using SafeLink NSTU, you acknowledge that you have read, understood, and agree to be bound by these terms. These terms may be updated from time to time, and your continued use of the app constitutes acceptance of any changes.\n\n2. Description of Service\nSafeLink NSTU provides a platform for students and faculty to access university resources, receive notifications, and engage with the university community. The app may include features such as course schedules, grades, announcements, and communication tools.',
                            style: TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Agree button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: const Color(0xFF6FB3FF),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.studentProfile);
                  },
                  child: const Text('Agree and Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
