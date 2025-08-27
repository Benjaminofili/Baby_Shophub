// Updated main.dart with Admin routing
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login.dart';
import 'screens/auth/signup.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/customer/search_page.dart';
import 'screens/customer/categories.dart';
import 'screens/customer/favorites.dart';
import 'screens/customer/category_products.dart';
import 'screens/customer/main_wrapper.dart';
import 'screens/admin/admin_wrapper.dart';
import 'services/deep_link_service.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDebugMode) {
    FlutterError.onError = (details) => {}; // Hide errors
  }

  // Initialize Supabase with proper auth flow
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep links after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.initialize(context);

      // Optional: Print test URLs for debugging
      if (mounted) {
        DeepLinkService.testDeepLinks();
      }
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyShopHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home:
      // CheckoutScreen(cartItems: [], totalAmount: 67.00,),
      AuthWrapper(),
      onGenerateRoute: AppRoutes.generateRoute, // Use the route generator
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),

        // Customer routes
        '/home': (context) => const MainWrapperPage(), // Main wrapper for customer
        '/main': (context) => const MainWrapperPage(), // Alternative route

        // Admin routes
        '/admin': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final initialIndex = args?['initialIndex'] as int? ?? 0;
          return AdminWrapper(initialIndex: initialIndex);
        },

        '/search': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final query = args?['query'] as String?;
          return SearchPage(initialQuery: query);
        },

        // Keep standalone versions for when they're accessed directly
        '/categories-standalone': (context) => const CategoriesPage(),
        '/favorites-standalone': (context) => const FavoritesPage(),

        '/category-products': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final category = args?['category'] as String? ?? 'Unknown';
          return CategoryProductsPage(categoryName: category);
        },
      },
    );
  }
}