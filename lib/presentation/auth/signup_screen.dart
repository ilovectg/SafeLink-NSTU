import 'package:flutter/material.dart';
import '../../config/routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import '../../core/utils/validators.dart';
import 'package:flutter/foundation.dart';
import 'controllers/profile_controller.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E5BA8),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                
                // University Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFFE8F0F7),
                        child: const Icon(
                          Icons.shield,
                          size: 50,
                          color: Color(0xFF1E5BA8),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Create Account heading
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Sign up with your institutional email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Form Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email label
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        _buildInput(
                          controller: _emailController,
                          hint: 'Enter your email',
                          icon: Icons.email_outlined,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password label
                        Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        _buildInput(
                          controller: _passwordController,
                          hint: 'Create a password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          isPassword: true,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Confirm Password label
                        Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        _buildInput(
                          controller: _confirmController,
                          hint: 'Confirm your password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          isConfirm: true,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Info box for staff
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFBBDEFB),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF1E5BA8), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Staff: Use Login page (no signup needed)',
                                  style: TextStyle(
                                    color: const Color(0xFF1E5BA8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sign Up button
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E5BA8),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E5BA8).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Login link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                                child: Text(
                                  'Login',
                                  style: const TextStyle(
                                    color: Color(0xFF1E5BA8),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    final shouldObscure = isPassword ? _obscurePassword : isConfirm ? _obscureConfirm : obscure;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: shouldObscure,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E1E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF1E5BA8), size: 22),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon: (isPassword || isConfirm)
              ? IconButton(
                  icon: Icon(
                    shouldObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPassword) {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirm = !_obscureConfirm;
                      }
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          errorStyle: const TextStyle(fontSize: 12),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) {
          if (hint.toLowerCase().contains('email')) {
            if (v == null || !Validators.isValidEmail(v))
              return 'Enter a valid email';
            if (!v.trim().toLowerCase().endsWith('@student.nstu.edu.bd'))
              return 'Use institutional student email (@student.nstu.edu.bd)';
            return null;
          }

          // Password validation
          if (hint.toLowerCase().contains('password') || hint.toLowerCase().contains('confirm')) {
            if (v == null || v.isEmpty) {
              return 'Password is required';
            }
            if (v.length < 6) {
              return 'Must be at least 6 characters';
            }
            return null;
          }

          return null;
        },
      ),
    );
  }

  void _submit() async {
    // Validate form first
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields correctly'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Check password match
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final email = _emailController.text.trim();

    // Store email for later editing
    ProfileController.instance.setSignupEmail(email);

    // Show location permission dialog before creating account
    _showLocationPermissionDialog(context);
  }

  void _showLocationPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E8F5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.location_on, color: Color(0xFF1E5BA8), size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enable Location Access',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'SafeLink requires your device location to provide mapping and location-based alerts. Please allow location access to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location permission is required to sign up'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: const Text(
                    'Deny',
                    style: TextStyle(
                      color: Color(0xFF1E1E1E),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      // Proceed with account creation after location permission
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      final auth = AuthController();
                      final user = await auth.createUserWithEmailVerification(email, password);

                      if (!mounted) return;

                      if (user != null) {
                        Navigator.pushReplacementNamed(
                          context,
                          '/email-verification',
                          arguments: {'email': email, 'password': password},
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to create account. Please check your email domain (@student.nstu.edu.bd)',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      backgroundColor: const Color(0xFF1E5BA8),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
