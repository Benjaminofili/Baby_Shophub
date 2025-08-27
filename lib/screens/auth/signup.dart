import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../components/Validatetextfield.dart';
import '../../components/button.dart';
import '../../components/dialogs.dart';
import '../../theme.dart';
import '../../services/supabase_auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2 || value.length > 100) {
      return 'Name must be between 2 and 100 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (value.length > 100) {
      return 'Email must not exceed 100 characters';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length > 20) {
        return 'Phone number must not exceed 20 characters';
      }
      final phoneRegex = RegExp(r'^[0-9+\-() ]*$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Invalid phone number format';
      }
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value != null && value.isNotEmpty && value.length > 255) {
      return 'Address must not exceed 255 characters';
    }
    return null;
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await SupabaseAuthService.register(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          address: addressController.text.trim().isEmpty
              ? null
              : addressController.text.trim(),
          phoneNumber: phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
        );

        if (result['success']) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.success, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Account Created!',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ],
                ),
                content: Text(
                  'Your account has been created successfully! Please check your email to verify your account before signing in.',
                  style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to login
                    },
                    child: Text(
                      'Got it!',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                backgroundColor: AppTheme.backgroundLight,
                elevation: 8,
              ),
            );
          }
        } else {
          showDialog(
            context: context,
            builder: (context) => ErrorDialog(
              title: 'Registration Error',
              message: result['message'],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await SupabaseAuthService.signInWithGoogle();

      if (result['success']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const SuccessDialog(
              message:
                  'Google account connected successfully! Welcome to BabyShop!',
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => ErrorDialog(
            title: 'Registration Error',
            message: result['message'],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => const ErrorDialog(
          title: 'Registration Error',
          message: 'Google sign-up failed. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withValues(alpha: 0.2),
              AppTheme.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.22,
                      constraints: const BoxConstraints(
                        minWidth: 200,
                        maxWidth: 450,
                        minHeight: 150,
                        maxHeight: 300,
                      ),
                      child: Image.asset(
                        'assets/logo.webp',
                        fit: BoxFit.contain,
                      ),
                    ).animate().fadeIn(duration: 800.ms),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                              'Join BabyShop!',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black.withValues(alpha: 0.1),
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.2, end: 0),
                        SizedBox(height: 8),
                        Text(
                          'Create your account to start shopping.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                        SizedBox(height: 20),
                        ValidatedTextField(
                              hintText: 'Full Name *',
                              controller: nameController,
                              validator: _validateName,
                              enabled: !_isLoading,
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.grey,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 300.ms)
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: 16),
                        ValidatedTextField(
                              hintText: 'E-mail *',
                              controller: emailController,
                              validator: _validateEmail,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icon(Icons.email, color: Colors.grey),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 400.ms)
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: 16),
                        ValidatedTextField(
                              hintText: 'Password *',
                              obscureText: true,
                              isPassword: true,
                              controller: passwordController,
                              validator: _validatePassword,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.visiblePassword,
                              prefixIcon: Icon(Icons.lock, color: Colors.grey),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 500.ms)
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: 16),
                        ValidatedTextField(
                              hintText: 'Confirm Password *',
                              obscureText: true,
                              isPassword: true,
                              controller: confirmPasswordController,
                              validator: _validateConfirmPassword,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.visiblePassword,
                              prefixIcon: Icon(Icons.lock, color: Colors.grey),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 600.ms)
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: 16),
                        ValidatedTextField(
                              hintText: 'Address (Optional)',
                              controller: addressController,
                              validator: _validateAddress,
                              enabled: !_isLoading,
                              // maxLines: 3,
                              prefixIcon: Icon(Icons.home, color: Colors.grey),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 700.ms)
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: 16),
                        ValidatedTextField(
                              hintText: 'Phone Number (Optional)',
                              controller: phoneController,
                              validator: _validatePhoneNumber,
                              enabled: !_isLoading,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icon(Icons.phone, color: Colors.grey),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 800.ms)
                            .slideX(begin: -0.1, end: 0),
                        SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primary.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CustomButton(
                            text: _isLoading
                                ? 'CREATING ACCOUNT...'
                                : 'CREATE ACCOUNT',
                            onPressed: _isLoading ? null : _handleSignUp,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 900.ms),
                        if (_isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                'or sign up with',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.g_mobiledata,
                                color: Colors.red,
                                size: 32,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : _handleGoogleSignUp,
                            ),
                            SizedBox(width: 24),
                            IconButton(
                              icon: Icon(
                                Icons.facebook,
                                color: Colors.blue,
                                size: 32,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => showDialog(
                                      context: context,
                                      builder: (context) =>
                                          const ComingSoonDialog(
                                            feature: 'Facebook Sign Up',
                                          ),
                                    ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 600.ms, delay: 1100.ms),
                        SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              "Already have an account? Sign In",
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 1200.ms),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
