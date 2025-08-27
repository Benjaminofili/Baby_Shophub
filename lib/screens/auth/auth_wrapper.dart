// Updated auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import '../customer/main_wrapper.dart'; // Changed from Home.dart
import 'splash.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Get current session
      final session = Supabase.instance.client.auth.currentSession;

      // Wait minimum 1.5 seconds for smooth splash experience
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isAuthenticated = session != null;
          _isInitializing = false;
        });
      }
    } catch (e) {
      // Handle any auth errors
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing
    if (_isInitializing) {
      return const SplashScreen();
    }

    // Listen to auth changes after initial check
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.signedIn,
        _isAuthenticated ? Supabase.instance.client.auth.currentSession : null,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session != null) {
          return const MainWrapperPage(); // Changed from HomePageDemo
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
