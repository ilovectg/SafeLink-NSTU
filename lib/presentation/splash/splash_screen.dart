import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_state_service.dart';
import '../../config/routes/app_routes.dart';
import '../auth/controllers/profile_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    // Keep splash showing for 5 seconds then check auth and navigate
    Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      await _checkAuthAndNavigate();
    });
  }

  /// Check authentication state and navigate accordingly
  Future<void> _checkAuthAndNavigate() async {
    try {
      // First check Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        // Not logged in, go to welcome screen
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      // Load profile data for all users (students, proctors, security staff)
      await ProfileController.instance.loadFromPrefs();
      await ProfileController.instance.loadFromFirestore();

      // User is logged in Firebase, get saved role from SharedPreferences
      final authState = AuthStateService.instance;
      final savedRole = await authState.getSavedRole();

      if (savedRole == null) {
        // No saved role, force re-login (corrupted state)
        print(
          '[Splash] Firebase user exists but no saved role, clearing auth...',
        );
        await authState.clearLoginState();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      // Navigate based on role
      if (!mounted) return;

      if (savedRole == 'student') {
        Navigator.pushReplacementNamed(context, AppRoutes.studentProfile);
      } else if (savedRole == 'proctorial') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
          arguments: 'proctorial body',
        );
      } else if (savedRole == 'security') {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
          arguments: 'security body',
        );
      } else {
        // Unknown role, force re-login
        print('[Splash] Unknown role: $savedRole, clearing auth...');
        await authState.clearLoginState();
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      // On any error, go to welcome screen
      print('[Splash] Error checking auth: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/splash_logo.png',
      width: 246,
      height: 246,
      errorBuilder: (context, error, stack) => const FlutterLogo(size: 246),
      fit: BoxFit.contain,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F2FF), Color(0xFF6EA8FF), Color(0xFF2D6FB3)],
            stops: [0.0, 0.6, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: logo,
              ),
            ),
            const SizedBox(height: 24),
            // Improved title block: translucent rounded backdrop + strong typography
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Safe',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Warm contrasting gradient for 'Link' (not blue) to improve legibility
                  _GradientText(
                    'Link',
                    // Muted gold -> amber for professional contrast against blue
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB86B), Color(0xFFD97706)],
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NSTU',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper widget to draw gradient text
class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  final Color strokeColor;
  final double strokeWidth;

  const _GradientText(
    this.text, {
    Key? key,
    required this.gradient,
    this.style = const TextStyle(),
    Color? strokeColor,
    double? strokeWidth,
  }) : strokeColor = strokeColor ?? const Color(0x44000000),
       strokeWidth = strokeWidth ?? 2.0,
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // Draw stroke underneath, then gradient-filled text on top
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Stroke layer
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // Gradient fill layer
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          blendMode: BlendMode.srcIn,
          child: Text(text, style: style.copyWith(color: Colors.white)),
        ),
      ],
    );
  }
}
