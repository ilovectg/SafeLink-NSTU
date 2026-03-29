import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _deptController = TextEditingController();
  final _sessionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;
  final _auth = AuthController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _studentIdFocus = FocusNode();
  final FocusNode _deptFocus = FocusNode();
  final FocusNode _sessionFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  
    // Field completion tracking
    bool _nameCompleted = false;
    bool _studentIdCompleted = false;
    bool _deptCompleted = false;
    bool _sessionCompleted = false;
    bool _phoneCompleted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
    
      // Add listeners to track field completion
      _nameController.addListener(() => setState(() => _nameCompleted = _nameController.text.trim().isNotEmpty));
      _studentIdController.addListener(() => setState(() => _studentIdCompleted = _studentIdController.text.trim().isNotEmpty));
      _deptController.addListener(() => setState(() => _deptCompleted = _deptController.text.trim().isNotEmpty));
      _sessionController.addListener(() => setState(() => _sessionCompleted = _sessionController.text.trim().isNotEmpty));
      _phoneController.addListener(() => setState(() => _phoneCompleted = _phoneController.text.trim().length >= 7));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _deptController.dispose();
    _sessionController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _studentIdFocus.dispose();
    _deptFocus.dispose();
    _sessionFocus.dispose();
    _phoneFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    // Retrieve email/password passed via arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args != null && args['email'] is String
        ? args['email'] as String
        : '';
    final password = args != null && args['password'] is String
        ? args['password'] as String
        : '';

    // Call backend signUp with full profile
    final success = await _auth.signUp(
      name: _nameController.text.trim(),
      email: email,
      password: password,
      studentId: _studentIdController.text.trim(),
      department: _deptController.text.trim(),
      session: _sessionController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (success) {
      // Save profile details locally for editing
      ProfileController.instance.setProfileSetup(
        name: _nameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        department: _deptController.text.trim(),
        session: _sessionController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      ProfileController.instance.updateAll(email: email);
      Navigator.pushReplacementNamed(context, AppRoutes.rules);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create account')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final _emailArg = args != null && args['email'] is String ? args['email'] as String : '';
    final _passwordArg = args != null && args['password'] is String ? args['password'] as String : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
      final completedFields = [_nameCompleted, _studentIdCompleted, _deptCompleted, _sessionCompleted, _phoneCompleted].where((e) => e).length;
      final totalFields = 5;
      final progress = completedFields / totalFields;

    return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/email-verification',
              arguments: {'email': _emailArg, 'password': _passwordArg},
            );
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Center(
                      child: Container(
                          padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                            borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D7BF2).withOpacity(0.3),
                                blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                              BoxShadow(
                                color: const Color(0xFF2D7BF2).withOpacity(0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                          ],
                        ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ],
                        ),
                      ),
                    ),
                      const SizedBox(height: 32),
                    
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Complete Your Profile',
                            style: TextStyle(
                                fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                                letterSpacing: -0.5,
                                height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                            const SizedBox(height: 12),
                          Text(
                              'Help us personalize your experience',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                                height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                      const SizedBox(height: 32),
                    
                      // Progress Bar with Statistics
                    Container(
                        padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                      ),
                        child: Column(
                        children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.account_circle_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Profile Progress',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white.withOpacity(0.95) : const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$completedFields of $totalFields fields completed',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: progress == 1.0 
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : [const Color(0xFF6EB9F9).withOpacity(0.2), const Color(0xFF2D7BF2).withOpacity(0.2)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: progress == 1.0 
                                        ? Colors.white
                                        : const Color(0xFF2D7BF2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDark 
                                        ? Colors.white.withOpacity(0.1)
                                        : const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    height: 8,
                                    width: MediaQuery.of(context).size.width * 0.85 * progress,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2), Color(0xFF1E40AF)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2D7BF2).withOpacity(0.5),
                                          blurRadius: 8,
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
                      const SizedBox(height: 32),
                    
                    // Form Fields
                    _buildProfileField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'e.g., John Doe',
                      icon: Icons.person_rounded,
                      focusNode: _nameFocus,
                      isDark: isDark,
                        isCompleted: _nameCompleted,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                    ),
                      const SizedBox(height: 20),
                    
                    _buildProfileField(
                      controller: _studentIdController,
                      label: 'Student ID',
                      hint: 'e.g., 1902056',
                      icon: Icons.badge_rounded,
                      focusNode: _studentIdFocus,
                      isDark: isDark,
                        isCompleted: _studentIdCompleted,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your student ID' : null,
                    ),
                      const SizedBox(height: 20),
                    
                    _buildProfileField(
                      controller: _deptController,
                      label: 'Department',
                      hint: 'e.g., Computer Science & Engineering',
                      icon: Icons.school_rounded,
                      focusNode: _deptFocus,
                      isDark: isDark,
                        isCompleted: _deptCompleted,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your department' : null,
                    ),
                      const SizedBox(height: 20),
                    
                    _buildProfileField(
                      controller: _sessionController,
                      label: 'Session',
                      hint: 'e.g., 2019-20',
                      icon: Icons.calendar_today_rounded,
                      focusNode: _sessionFocus,
                      isDark: isDark,
                        isCompleted: _sessionCompleted,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your session' : null,
                    ),
                      const SizedBox(height: 20),
                    
                    _buildProfileField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'e.g., +880 1712-345678',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      focusNode: _phoneFocus,
                      isDark: isDark,
                        isCompleted: _phoneCompleted,
                      validator: (v) => (v == null || v.trim().length < 7) ? 'Please enter a valid phone number' : null,
                    ),
                      const SizedBox(height: 36),
                    
                    // Complete Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6EB9F9), Color(0xFF2D7BF2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D7BF2).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.check_circle_rounded, size: 22),
                                  SizedBox(width: 10),
                                  Text(
                                    'Complete Setup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isDark,
    required bool isCompleted,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF374151),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 6),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
              width: isCompleted ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isCompleted
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: isCompleted ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: const Color(0xFF2D7BF2),
                  size: 22,
                ),
              ),
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2D7BF2),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              errorStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
