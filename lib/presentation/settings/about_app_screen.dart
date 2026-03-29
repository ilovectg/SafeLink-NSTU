import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F9FF),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 86,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark, statusBarIconBrightness: Brightness.light),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.shield, color: Color(0xFF0A73FF), size: 32),
              ),
            ),
            const SizedBox(width: 12),
            const Text('SafeLink NSTU',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4)),
          ],
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F9FF), Color(0xFFE8F0FF), Color(0xFFF6ECFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Application',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A1A), letterSpacing: 0.2),
                ),
                const SizedBox(height: 16),
                _infoCard(
                  context,
                  title: 'What is SafeLink NSTU?',
                  icon: Icons.security,
                  content:
                      'SafeLink NSTU keeps your campus identity, safety tools, and profile in one secure place. It is built to be fast, reliable, and easy to navigate on busy student schedules.',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  context,
                  title: 'Key things you can do',
                  icon: Icons.check_circle_outline,
                  content:
                      '• Update and keep your student details up to date.\n• Access alerts and campus guidelines quickly.\n• Control notifications so you only see what matters.\n• Reach help resources and support when needed.',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  context,
                  title: 'Privacy & security',
                  icon: Icons.verified_user_outlined,
                  content:
                      'Your data stays protected with secure storage. Avoid sharing your password, and log out on shared devices. For any issue, contact the NSTU support desk.',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  context,
                  title: 'Need help?',
                  icon: Icons.support_agent,
                  content:
                      'Visit Help/FAQ from Settings or reach the NSTU support team. We ship updates regularly to improve stability and add features based on your feedback.',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navIcon(context, Icons.home_rounded, 'Home', () {
                  Navigator.pushNamedAndRemoveUntil(context, '/student-profile', (route) => false);
                }),
                _navIcon(context, Icons.settings_rounded, 'Settings', () {
                  Navigator.pushNamed(context, '/settings');
                }),
                _navIcon(context, Icons.arrow_back_rounded, 'Back', () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context,
      {required String title, required IconData icon, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.45)),
        ],
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D7BF2).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}
