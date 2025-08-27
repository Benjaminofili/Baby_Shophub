// Updated app_routes.dart with organized screen imports
import 'package:flutter/material.dart';
import '../screens/customer/search_page.dart';
import '../screens/customer/categories.dart';
import '../screens/customer/favorites.dart';
import '../screens/customer/category_products.dart';
import '../screens/customer/main_wrapper.dart';
import '../screens/customer/shopping.dart';
import '../screens/customer/profile.dart';
import '../screens/customer/product_detail.dart';
import '../screens/customer/checkout.dart';
import '../screens/customer/order_history.dart';
import '../screens/customer/support.dart';
import '../screens/customer/help.dart';

// Admin imports
import '../screens/admin/admin_wrapper.dart';
import '../screens/admin/admin_orders_screen.dart';

class AppRoutes {
  // Customer routes
  static const String home = '/';
  static const String main = '/main';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String categories = '/categories';
  static const String favorites = '/favorites';
  static const String categoryProducts = '/category-products';
  static const String productDetail = '/product-detail';
  static const String orderHistory = '/order-history'; // New route

  static const String support = '/support'; // New route for feedback/support
  static const String help = '/help'; // New route for help

  // Admin routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';
  static const String adminReviews = '/admin/reviews';
  static const String adminCategories = '/admin/categories';
  static const String adminAnalytics = '/admin/analytics';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      case main:
        final args = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => MainWrapperPage(initialIndex: args ?? 0),
        );

      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialQuery = args?['query'] as String?;
        return MaterialPageRoute(
          builder: (_) => SearchPage(initialQuery: initialQuery),
        );

      case cart:
        return MaterialPageRoute(
          builder: (_) => ShoppingCart(),
        );

      case checkout:
        final args = settings.arguments as Map<String, dynamic>?;
        final cartItems = args?['cartItems'] as List<Map<String, dynamic>>?;
        final totalAmount = args?['totalAmount'] as double?;

        if (cartItems == null || totalAmount == null) {
          return MaterialPageRoute(
            builder: (_) => ShoppingCart(),
          );
        }

        return MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            cartItems: cartItems,
            totalAmount: totalAmount,
          ),
        );

      case categories:
        return MaterialPageRoute(builder: (_) => const CategoriesPage());

      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesPage());

      case categoryProducts:
        final args = settings.arguments as Map<String, dynamic>?;
        final category = args?['category'] as String?;
        return MaterialPageRoute(
          builder: (_) => CategoryProductsPage(
            categoryName: category ?? 'Unknown Category',
          ),
        );

      case productDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final productId = args?['productId'] as String?;
        if (productId == null) {
          return MaterialPageRoute(
            builder: (_) => const MainWrapperPage(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProductDetail(productId: productId),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());



      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());

      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());

    // Admin Routes
      case admin:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => AdminWrapper(initialIndex: initialIndex),
        );

      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminWrapper(initialIndex: 0),
        );

      case adminProducts:
        return MaterialPageRoute(
          builder: (_) => const AdminWrapper(initialIndex: 1),
        );

      case adminOrders:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialStatus = args?['initialStatus'] as String?;
        return MaterialPageRoute(
          builder: (_) => AdminOrdersScreen(initialStatus: initialStatus),
        );

      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => const AdminWrapper(initialIndex: 3),
        );

      case adminReviews:
        return MaterialPageRoute(
          builder: (_) => const AdminWrapper(initialIndex: 4),
        );

      case adminCategories:
        return MaterialPageRoute(
          builder: (_) => const AdminWrapper(initialIndex: 5),
        );

      case adminAnalytics:
        return MaterialPageRoute(
          builder: (_) => const AdminWrapper(initialIndex: 6),
        );

      default:
        return MaterialPageRoute(builder: (_) => const MainWrapperPage());
    }
  }

  // Helper methods for customer navigation
  static void navigateToProductDetail(BuildContext context, String productId) {
    Navigator.pushNamed(
      context,
      productDetail,
      arguments: {'productId': productId},
    );
  }

  static void navigateToCategory(BuildContext context, String categoryName) {
    Navigator.pushNamed(
      context,
      categoryProducts,
      arguments: {'category': categoryName},
    );
  }

  static void navigateToSearch(BuildContext context, {String? query}) {
    Navigator.pushNamed(
      context,
      search,
      arguments: {'query': query},
    );
  }

  static void navigateToCheckout(
      BuildContext context, {
        required List<Map<String, dynamic>> cartItems,
        required double totalAmount,
      }) {
    Navigator.pushNamed(
      context,
      checkout,
      arguments: {
        'cartItems': cartItems,
        'totalAmount': totalAmount,
      },
    );
  }

  static void navigateToOrderHistory(BuildContext context) {
    Navigator.pushNamed(context, orderHistory);
  }


  static void navigateToSupport(BuildContext context) {
    Navigator.pushNamed(context, support);
  }

  static void navigateToHelp(BuildContext context) {
    Navigator.pushNamed(context, help);
  }

  // Helper methods for admin navigation
  static void navigateToAdmin(BuildContext context, {int initialIndex = 0}) {
    Navigator.pushNamed(
      context,
      admin,
      arguments: {'initialIndex': initialIndex},
    );
  }

  static void navigateToAdminDashboard(BuildContext context) {
    Navigator.pushNamed(context, adminDashboard);
  }

  static void navigateToAdminProducts(BuildContext context) {
    Navigator.pushNamed(context, adminProducts);
  }

  static void navigateToAdminOrders(BuildContext context, {String? initialStatus}) {
    Navigator.pushNamed(
      context,
      adminOrders,
      arguments: {'initialStatus': initialStatus},
    );
  }

  static void navigateToAdminUsers(BuildContext context) {
    Navigator.pushNamed(context, adminUsers);
  }

  static void navigateToAdminReviews(BuildContext context) {
    Navigator.pushNamed(context, adminReviews);
  }

  static void navigateToAdminCategories(BuildContext context) {
    Navigator.pushNamed(context, adminCategories);
  }

  static void navigateToAdminAnalytics(BuildContext context) {
    Navigator.pushNamed(context, adminAnalytics);
  }

  // Quick admin access check
  static bool isAdminRoute(String? routeName) {
    return routeName?.startsWith('/admin') ?? false;
  }
}