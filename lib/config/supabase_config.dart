// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://uplzgksjtlxynpcshtme.supabase.co';
  static const String supabaseAnonKey =
'sb_publishable_y9QC1dF_4rZAkhqC5Xm1Eg_m8Uqor8K';

  // App-specific configuration
  static const String appName = 'BabyShopHub';
  static const String appVersion = '1.0.0';

  // Feature flags
  static const bool enableSocialLogin =
      false; // Set to true when implementing OAuth
  static const bool enablePushNotifications = false;
  static const bool enableAnalytics = false;
}
