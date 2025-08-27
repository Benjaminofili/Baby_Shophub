// lib/services/deep_link_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Initialize deep link handling
  Future<void> initialize(BuildContext context) async {
    try {
      // Handle app launch from deep link when app is closed
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('App launched with deep link: $initialUri');
        // Small delay to ensure app is fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          await _handleDeepLink(context, initialUri);
        }
      }

      // Handle deep links when app is running or in background
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) async {
          debugPrint('Received deep link while app running: $uri');
          if (context.mounted) {
            await _handleDeepLink(context, uri);
          }
        },
        onError: (err) {
          debugPrint('Deep link error: $err');
        },
      );

      debugPrint('DeepLinkService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing DeepLinkService: $e');
    }
  }

  // Handle incoming deep links
  Future<void> _handleDeepLink(BuildContext context, Uri uri) async {
    debugPrint('Processing deep link: $uri');
    debugPrint('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    debugPrint('Query params: ${uri.queryParameters}');
    debugPrint('Fragment: ${uri.fragment}');

    try {
      // Handle Supabase auth deep links (HTTPS)
      if (uri.scheme == 'https' &&
          uri.host == 'xwnlkrxdmpocxyetksdi.supabase.co') {
        await _handleSupabaseAuthCallback(context, uri);
        return;
      }

      // Handle custom app scheme deep links
      if (uri.scheme == 'babyshophub') {
        await _handleCustomAppRoute(context, uri);
        return;
      }

      // Fallback for any other deep links
      debugPrint('Unhandled deep link scheme: ${uri.scheme}');
      _navigateToDefaultScreen(context);
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      _showErrorMessage(context, 'Error processing link: ${e.toString()}');
      _navigateToDefaultScreen(context);
    }
  }

  // Handle Supabase authentication callbacks
  Future<void> _handleSupabaseAuthCallback(
    BuildContext context,
    Uri uri,
  ) async {
    debugPrint('Handling Supabase auth callback');

    try {
      if (uri.path.contains('/auth/v1/callback') ||
          uri.path.contains('/auth/v1/verify')) {
        debugPrint('Processing Supabase auth URL...');

        final response = await Supabase.instance.client.auth.getSessionFromUrl(
          uri,
        );

        if (response.session?.user != null) {
          if (context.mounted) {
            _showSuccessMessage(
              context,
              'Email verified successfully! Welcome to BabyShopHub!',
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          }
        } else {
          throw Exception('Authentication failed');
        }
      } else {
        final redirectTo = uri.queryParameters['redirect_to'];
        if (redirectTo != null) {
          final redirectUri = Uri.parse(redirectTo);
          await _handleDeepLink(context, redirectUri);
        } else {
          _navigateToDefaultScreen(context);
        }
      }
    } on AuthException catch (e) {
      // LOG detailed error for debugging
      debugPrint('Auth callback error: ${e.message}');

      if (context.mounted) {
        // Show generic user-friendly message
        String errorMessage = 'Email verification failed. Please try again.';

        if (e.message.toLowerCase().contains('expired')) {
          errorMessage =
              'Verification link has expired. Please check for a newer email or request a new verification.';
        }

        _showErrorMessage(context, errorMessage);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      // LOG detailed error for debugging
      debugPrint('Auth callback unexpected error: $e');

      if (context.mounted) {
        _showErrorMessage(
          context,
          'Email verification failed. Please try again.',
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // Handle custom app routes (babyshophub://)
  Future<void> _handleCustomAppRoute(BuildContext context, Uri uri) async {
    final path = uri.path.toLowerCase();
    final queryParams = uri.queryParameters;

    debugPrint('Handling custom app route: $path');

    // Check if user is authenticated for protected routes
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    switch (path) {
      case '/login':
        debugPrint('Navigating to login');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        break;

      case '/signup':
        debugPrint('Navigating to signup');
        Navigator.pushNamedAndRemoveUntil(context, '/signup', (route) => false);
        break;

      case '/home':
        debugPrint('Navigating to home');
        if (isLoggedIn) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          _showErrorMessage(context, 'Please log in to access your account');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        break;

      case '/reset-password':
        debugPrint('Navigating to reset password');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        if (context.mounted) {
          _showInfoMessage(context, 'Please enter your new password');
        }
        break;

      case '/product':
        final productId = queryParams['id'];
        debugPrint('Navigating to product: $productId');

        if (productId != null) {
          // For now, navigate to home and show message
          // Later you can implement: Navigator.pushNamed(context, '/product', arguments: productId);
          if (isLoggedIn) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
            if (context.mounted) {
              _showInfoMessage(
                context,
                'Product ID: $productId (feature coming soon!)',
              );
            }
          } else {
            _showErrorMessage(context, 'Please log in to view products');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        } else {
          _navigateToDefaultScreen(context);
        }
        break;

      case '/category':
        final categoryId = queryParams['id'];
        debugPrint('Navigating to category: $categoryId');

        if (isLoggedIn) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          if (context.mounted && categoryId != null) {
            _showInfoMessage(
              context,
              'Category: $categoryId (feature coming soon!)',
            );
          }
        } else {
          _showErrorMessage(context, 'Please log in to browse categories');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
        break;

      case '/auth/callback':
        // Handle custom auth callbacks
        debugPrint('Custom auth callback');
        _navigateToDefaultScreen(context);
        break;

      default:
        debugPrint('Unknown route: $path, navigating to default screen');
        _navigateToDefaultScreen(context);
        break;
    }
  }

  // Navigate to appropriate default screen based on auth state
  void _navigateToDefaultScreen(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

    if (isLoggedIn) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Show success message
  void _showSuccessMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show error message
  void _showErrorMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show info message
  void _showInfoMessage(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Generate deep links for sharing
  static String generateProductLink(String productId) {
    return 'babyshophub://product?id=$productId';
  }

  static String generateCategoryLink(String categoryId) {
    return 'babyshophub://category?id=$categoryId';
  }

  static String generateHomeLink() {
    return 'babyshophub://home';
  }

  static String generateLoginLink() {
    return 'babyshophub://login';
  }

  static String generateSignupLink() {
    return 'babyshophub://signup';
  }

  // Test deep link functionality
  static void testDeepLinks() {
    debugPrint('=== BabyShopHub Deep Link Test URLs ===');
    debugPrint('Home: ${generateHomeLink()}');
    debugPrint('Login: ${generateLoginLink()}');
    debugPrint('Signup: ${generateSignupLink()}');
    debugPrint('Product: ${generateProductLink('baby-stroller-123')}');
    debugPrint('Category: ${generateCategoryLink('feeding-bottles')}');
    debugPrint('=====================================');
  }

  // Dispose subscription
  void dispose() {
    debugPrint('Disposing DeepLinkService');
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
