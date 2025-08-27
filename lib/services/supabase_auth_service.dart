import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // For debugPrint


class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Configure Google Sign-In for BabyShop
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Your Android Client ID
    clientId:
    '976211715627-j6vucgf2ktih8at96m00lsst3mq3a898.apps.googleusercontent.com',
    // Your Web Client ID (configured in Supabase)
    serverClientId:
    '976211715627-6f7a1mgbs1ii18e7b5dnv87buvkhokt9.apps.googleusercontent.com',
  );

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ================================
  // ADMIN CHECKING METHODS - NEW
  // ================================

  /// Check if current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return profile?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if a specific user is an admin
  static Future<bool> isUserAdmin(String userId) async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return profile?['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking user admin status: $e');
      return false;
    }
  }

  /// Get current user's role
  static Future<String> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return 'guest';

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return profile?['role'] ?? 'user';
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return 'user';
    }
  }

  /// Promote user to admin (only existing admins can do this)
  static Future<Map<String, dynamic>> promoteToAdmin(String userId) async {
    try {
      // Check if current user is admin
      if (!await isCurrentUserAdmin()) {
        return {
          'success': false,
          'message': 'Only admins can promote users to admin.',
        };
      }

      await _supabase
          .from('profiles')
          .update({
        'role': 'admin',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', userId);

      return {
        'success': true,
        'message': 'User successfully promoted to admin.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to promote user: $e',
      };
    }
  }

  /// Demote admin to regular user
  static Future<Map<String, dynamic>> demoteFromAdmin(String userId) async {
    try {
      // Check if current user is admin
      if (!await isCurrentUserAdmin()) {
        return {
          'success': false,
          'message': 'Only admins can demote users.',
        };
      }

      // Prevent self-demotion
      if (currentUser?.id == userId) {
        return {
          'success': false,
          'message': 'You cannot demote yourself.',
        };
      }

      await _supabase
          .from('profiles')
          .update({
        'role': 'user',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', userId);

      return {
        'success': true,
        'message': 'User successfully demoted to regular user.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to demote user: $e',
      };
    }
  }

  /// Require admin access - throws exception if not admin
  static Future<void> requireAdminAccess() async {
    if (!await isCurrentUserAdmin()) {
      throw Exception('Admin access required');
    }
  }

  // ================================
  // EXISTING METHODS (unchanged)
  // ================================

  // Regular email/password login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': 'Welcome back to BabyShop!',
          'user': response.user,
        };
      } else {
        return {'success': false, 'message': 'Login failed. Please try again.'};
      }
    } catch (e) {
      return {
        'success': false,
        'message':
        'Unable to sign in. Please check your credentials and try again.',
      };
    }
  }

  // Google Sign-In Method
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return {'success': false, 'message': 'Google sign-in was cancelled.'};
      }

      // Step 2: Get Google Auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return {
          'success': false,
          'message': 'Failed to get Google authentication tokens.',
        };
      }

      // Step 3: Sign in to Supabase with Google tokens
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user != null) {
        // Step 4: Create or update user profile
        await _createOrUpdateGoogleProfile(response.user!);

        return {
          'success': true,
          'message': 'Welcome to BabyShop! Google sign-in successful!',
          'user': response.user,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to authenticate with Google.',
        };
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return {
        'success': false,
        'message': 'Google sign-in failed. Please try again.',
      };
    }
  }

  // Alternative Google Sign-In using OAuth
  static Future<Map<String, dynamic>> signInWithGoogleOAuth() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'babyshophub://auth/callback',
      );

      return {'success': true, 'message': 'Redirecting to Google...'};
    } catch (e) {
      return {'success': false, 'message': 'Unable to start Google sign-in.'};
    }
  }

  // Helper: Create or update Google user profile
  static Future<void> _createOrUpdateGoogleProfile(User user) async {
    try {
      final userMetadata = user.userMetadata ?? {};
      final fullName =
          userMetadata['full_name'] ??
              userMetadata['name'] ??
              'BabyShop Customer';
      final avatarUrl = userMetadata['avatar_url'] ?? userMetadata['picture'];

      // Check if profile exists
      final existingProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile - default role is 'user'
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'phone': null,
          'address': null,
          'role': 'user', // Default role
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Update existing profile (don't change role)
        await _supabase
            .from('profiles')
            .update({
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Profile creation/update error: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  // Regular registration
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? address,
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'babyshophub://login',
        data: {'full_name': name, 'phone': phoneNumber, 'address': address},
      );

      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          address: address,
        );

        return {
          'success': true,
          'message':
          'Welcome to BabyShop! Please check your email to verify your account.',
          'user': response.user,
        };
      } else {
        return {
          'success': false,
          'message': 'Unable to create account. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to create account. Please try again.',
      };
    }
  }

  // Create user profile
  static Future<void> _createUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': name,
        'email': email,
        'phone': phoneNumber,
        'address': address,
        'avatar_url': null,
        'role': 'user', // Default role
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Profile creation error: $e');
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'babyshophub://reset-password',
      );
      return {
        'success': true,
        'message': 'Password reset email sent! Check your inbox.',
      };
    } catch (e) {
      return {
        'success': true,
        'message':
        'If an account exists, you will receive a password reset email.',
      };
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    String? phoneNumber,
    String? address,
  }) async {
    final user = currentUser;
    if (user == null) {
      return {
        'success': false,
        'message': 'Please sign in to update your profile.',
      };
    }

    try {
      await _supabase
          .from('profiles')
          .update({
        'full_name': name,
        'phone': phoneNumber,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', user.id);

      return {'success': true, 'message': 'Profile updated successfully'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to update profile. Please try again.',
      };
    }
  }

  // Utility getters
  static bool get isLoggedIn => currentUser != null;
  static String? get userEmail => currentUser?.email;
  static String? get userId => currentUser?.id;
}