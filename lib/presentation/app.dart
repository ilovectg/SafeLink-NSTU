import 'package:flutter/material.dart';
import '../config/theme/app_theme.dart';
import '../config/theme/theme_controller.dart';
import 'settings/help_screen.dart';
import '../config/routes/app_routes.dart';
import 'home/home_screen.dart';
import 'home/student_profile_screen.dart';
import 'home/map_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'auth/email_verification_screen.dart';
import 'auth/profile_setup_screen.dart';
import 'auth/rules_screen.dart';
import 'auth/forgot_password_screen.dart';
import 'home/alerts_screen.dart';
import 'home/alert_detail_screen.dart';
import 'splash/splash_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/edit_profile_screen.dart';
import 'settings/staff_profile_screen.dart';
import 'settings/about_app_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'onboarding/entry_screen.dart';
import '../firebase_test_page.dart';

class SafeLinkApp extends StatelessWidget {
  const SafeLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'SafeLink NSTU',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.signup: (context) => const SignupScreen(),
            '/email-verification': (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final email = args != null && args['email'] is String
                  ? args['email'] as String
                  : '';
              final password = args != null && args['password'] is String
                  ? args['password'] as String
                  : '';
              return EmailVerificationScreen(email: email, password: password);
            },
            AppRoutes.profileSetup: (context) => const ProfileSetupScreen(),
            AppRoutes.rules: (context) => const RulesScreen(),
            AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
            AppRoutes.alerts: (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final initial = args != null && args['initialFilter'] is String
                  ? args['initialFilter'] as String
                  : 'All';
              final isSecurity =
                  args != null &&
                  (args['isSecurity'] == true || args['role'] == 'security');
              return AlertsScreen(
                initialFilter: initial,
                isSecurity: isSecurity,
              );
            },
            AppRoutes.alertDetail: (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              return AlertDetailScreen(data: args ?? {});
            },
            AppRoutes.map: (context) {
              final args =
                  ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;
              final isStaffView = args?['isStaffView'] ?? false;
              final title = isStaffView ? 'Student Location' : 'Your Location';
              return MapScreen(title: title, isStaffView: isStaffView);
            },
            '/sos': (context) => const StudentProfileScreen(),
            AppRoutes.studentProfile: (context) => const StudentProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/staff-profile': (context) => const StaffProfileScreen(),
            '/about-app': (context) => const AboutAppScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/entry': (context) => const EntryScreen(),
            '/firebase_test': (context) => const FirebaseTestPage(),
            '/help': (context) => const HelpScreen(),
          },
        );
      },
    );
  }
}
