// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://xwnlkrxdmpocxyetksdi.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3bmxrcnhkbXBvY3h5ZXRrc2RpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUyMDI0ODUsImV4cCI6MjA3MDc3ODQ4NX0.nlLivPbtpQKqvcKxL6uymXre_a3Sc-rKJMSuLiV5pYc';

  // App-specific configuration
  static const String appName = 'BabyShopHub';
  static const String appVersion = '1.0.0';

  // Feature flags
  static const bool enableSocialLogin =
      false; // Set to true when implementing OAuth
  static const bool enablePushNotifications = false;
  static const bool enableAnalytics = false;
}
