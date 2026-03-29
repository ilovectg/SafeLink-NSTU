import 'package:flutter/material.dart';
import '../../core/widgets/back_button_widget.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args != null && args['role'] is String ? (args['role'] as String).toLowerCase() : 'student';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 86,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: const AppBarBackButton(),
        title: const Text('Help & FAQ'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6CC6FF), Color(0xFF2D7BF2), Color(0xFF4E46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: role == 'proctor' || role == 'security'
            ? [
                const _FaqItem(
                  question: 'How do I respond to an alert?',
                  answer: 'Open the Alerts screen, tap an alert and choose Accept or Forward. Use the quick actions to add notes or call the reporter.',
                ),
                const _FaqItem(
                  question: 'How to forward alerts to Security/Proctor?',
                  answer: 'Select an alert and use the Forward option to send it to the appropriate team. Add any relevant notes.',
                ),
                const _FaqItem(
                  question: 'Where do forwarded alerts appear?',
                  answer: 'Forwarded alerts appear in the Security dashboard under "Forwarded Alerts" for review and action.',
                ),
                const _FaqItem(
                  question: 'Who do I contact for support?',
                  answer: 'Contact proctor@office.nstu.edu.bd or security@office.nstu.edu.bd for operational help.',
                ),
              ]
            : const [
                _FaqItem(
                  question: 'How do I enable Dark Mode?',
                  answer: 'Go to Settings > Dark mode and toggle it on. The entire app will switch to night mode and remember your choice.',
                ),
                _FaqItem(
                  question: 'How to send an emergency alert?',
                  answer: 'Open the Student Profile screen and tap the red emergency button. Confirm to notify guardians and campus security.',
                ),
                _FaqItem(
                  question: 'Where can I see alert responses?',
                  answer: 'Tap the notification icon (bottom nav) to see responses from proctor/security. You will also see a badge count.',
                ),
                _FaqItem(
                  question: 'How to edit my profile?',
                  answer: 'Go to Settings > Profile details. Update your information and save.',
                ),
                _FaqItem(
                  question: 'Who do I contact for support?',
                  answer: 'Email support@safelink.nstu or contact your campus security office.',
                ),
              ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
