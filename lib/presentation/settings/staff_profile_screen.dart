import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/back_button_widget.dart';
import '../auth/controllers/profile_controller.dart';
import '../home/see_pulse_screen.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({Key? key}) : super(key: key);

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile data from Firestore
    Future.microtask(() async {
      await ProfileController.instance.loadFromPrefs();
      await ProfileController.instance.loadFromFirestore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 86,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        leading: AppBarBackButton(
          onTap: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.shield,
                  color: Color(0xFF0A73FF),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
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
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF7F7F7),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: ProfileController.instance,
            builder: (context, _) {
              final p = ProfileController.instance;
              final isProctor = p.role == 'proctorial';
              final isSecurity = p.role == 'security';
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
                              : [Colors.white, const Color(0xFFF8FBFF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2D7BF2).withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D7BF2).withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(
                                isProctor || isSecurity ? Icons.shield : Icons.person,
                                color: const Color(0xFF2D7BF2),
                                size: 50,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Name
                          Text(
                            p.name.isNotEmpty ? p.name : 'Staff Member',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Designation
                          if (p.designation.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                p.designation,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          
                          // Role Badge
                          Text(
                            isProctor ? 'Proctorial Body' : (isSecurity ? 'Security Body' : 'Staff'),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact Information Section
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Email Field
                    _buildInfoCard(
                      context,
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: p.email.isNotEmpty ? p.email : 'Not provided',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    // Phone Field
                    _buildInfoCard(
                      context,
                      icon: Icons.phone_outlined,
                      title: 'Phone Number',
                      value: p.phone.isNotEmpty ? p.phone : 'Not provided',
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Organization Info
                    Text(
                      'Organization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoCard(
                      context,
                      icon: Icons.business_outlined,
                      title: 'Institution',
                      value: 'Noakhali Science & Technology University',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoCard(
                      context,
                      icon: Icons.work_outline,
                      title: 'Department',
                      value: p.department.isNotEmpty ? p.department : (isProctor ? 'Proctorial Body' : 'Security Body'),
                      isDark: isDark,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Info Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D7BF2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2D7BF2).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF2D7BF2),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'To update your profile information, please contact the system administrator.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                    arguments: ProfileController.instance.role == 'proctorial' 
                        ? 'proctorial body' 
                        : 'security body',
                  );
                }),
                _navIcon(context, Icons.favorite, 'See Pulse', () {
                  // Navigate to see pulse locations
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SeePulseScreen(),
                    ),
                  );
                }),
                _navIcon(context, Icons.arrow_back, 'Back', () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2D7BF2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForLabel(label),
                color: const Color(0xFF2D7BF2),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D7BF2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Home':
        return Icons.home_rounded;
      case 'See Pulse':
        return Icons.favorite;
      case 'Back':
        return Icons.arrow_back_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2D7BF2).withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
