// File: lib/services/admin_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Product Management
  static Future<List<Map<String, dynamic>>> getAllProducts({
    String? category,
    String? searchQuery,
    bool? isActive,
  }) async {
    PostgrestFilterBuilder query = _supabase
        .from('products')
        .select('*');

    if (category != null) {
      query = query.eq('category', category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    String? subcategory,
    String? brand,
    String? ageRange,
    String? material,
    double? weightKg,
    String? dimensionsCm,
    required int stockQuantity,
    bool isActive = true,
    bool featured = false,
    bool safetyCertified = false,
    String? imageUrl,
    List<String>? imageUrls,
    List<String>? tags,
  }) async {
    final response = await _supabase.from('products').insert({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'age_range': ageRange,
      'material': material,
      'weight_kg': weightKg,
      'dimensions_cm': dimensionsCm,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'featured': featured,
      'safety_certified': safetyCertified,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'tags': tags,
    }).select().single();

    return response;
  }

  static Future<void> updateProduct(
      String productId,
      Map<String, dynamic> updates,
      ) async {
    await _supabase
        .from('products')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', productId);
  }

  static Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }

  // Category Management
  static Future<List<Map<String, dynamic>>> getAllCategories() async {
    final response = await _supabase
        .from('categories')
        .select('*')
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String? iconName,
    String? parentId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    final response = await _supabase.from('categories').insert({
      'name': name,
      'description': description,
      'icon_name': iconName,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_active': isActive,
    }).select().single();

    return response;
  }

  static Future<void> updateCategory(
      String categoryId,
      Map<String, dynamic> updates,
      ) async {
    await _supabase
        .from('categories')
        .update(updates)
        .eq('id', categoryId);
  }

  static Future<void> deleteCategory(String categoryId) async {
    await _supabase.from('categories').delete().eq('id', categoryId);
  }

  // Order Management
  static Future<List<Map<String, dynamic>>> getAllOrders({
    String? status,
    int limit = 50,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('orders')
          .select('*');

      if (status != null) {
        query = query.eq('status', status);
      }

      final ordersResponse = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final orders = List<Map<String, dynamic>>.from(ordersResponse);

      // Fetch user profiles and order items separately
      for (final order in orders) {
        final userId = order['user_id'];
        if (userId != null) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('id, full_name, email, phone')
                .eq('id', userId)
                .maybeSingle();
            order['profiles'] = profile;
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error fetching profile for user $userId: $e');
            }
            order['profiles'] = null;
          }
        }

        // Fetch order items
        try {
          final orderItems = await _supabase
              .from('order_items')
              .select('*, products(id, name, price, image_url)')
              .eq('order_id', order['id']);
          order['order_items'] = orderItems;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error fetching order items for order ${order['id']}: $e');
          }
          order['order_items'] = [];
        }
      }

      return orders;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();

      // Fetch user profile separately
      final userId = orderResponse['user_id'];
      if (userId != null) {
        try {
          final profile = await _supabase
              .from('profiles')
              .select('id, full_name, email, phone')
              .eq('id', userId)
              .maybeSingle();
          orderResponse['profiles'] = profile;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error fetching profile: $e');
          }
          orderResponse['profiles'] = null;
        }
      }

      // Fetch order items with products
      try {
        final orderItems = await _supabase
            .from('order_items')
            .select('*, products(id, name, price, image_url)')
            .eq('order_id', orderId);
        orderResponse['order_items'] = orderItems;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error fetching order items: $e');
        }
        orderResponse['order_items'] = [];
      }

      return orderResponse;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, int>> getOrdersSummary() async {
    final response = await _supabase
        .from('orders')
        .select('status');

    final data = response as List;
    final counts = <String, int>{
      'all': data.length,
      'pending': 0,
      'confirmed': 0,
      'processing': 0,
      'shipped': 0,
      'delivered': 0,
      'cancelled': 0,
      'returned': 0,
    };

    for (final order in data) {
      final status = order['status'] as String? ?? 'pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  static Future<void> updateOrderStatus(
      String orderId,
      String newStatus, {
        String? trackingNumber,
        String? adminNotes,
        DateTime? estimatedDelivery,
      }) async {
    final updates = {
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (trackingNumber != null) {
      updates['tracking_number'] = trackingNumber;
    }

    if (adminNotes != null) {
      updates['admin_notes'] = adminNotes;
    }

    if (estimatedDelivery != null) {
      updates['estimated_delivery'] = estimatedDelivery.toIso8601String();
    }

    // If order is delivered, set delivered_at
    if (newStatus == 'delivered') {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }

    await _supabase.from('orders').update(updates).eq('id', orderId);
  }

  // User Management
  static Future<List<Map<String, dynamic>>> getAllUsers({
    String? searchQuery,
    String? role,
    int limit = 100,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('profiles')
          .select('*');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('full_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching users: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, int>> getUsersCountByRole() async {
    final response = await _supabase
        .from('profiles')
        .select('role');

    final data = response as List;
    final counts = <String, int>{'user': 0, 'admin': 0};

    for (final profile in data) {
      final role = profile['role'] as String? ?? 'user';
      counts[role] = (counts[role] ?? 0) + 1;
    }

    return counts;
  }

  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    // Get user profile
    final profile = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

    // Get user orders
    final orders = await _supabase
        .from('orders')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Calculate total spent
    final totalSpentResponse = await _supabase
        .from('orders')
        .select('total_amount')
        .eq('user_id', userId)
        .eq('status', 'delivered');

    double totalSpent = 0;
    for (final order in totalSpentResponse) {
      totalSpent += (order['total_amount'] as num).toDouble();
    }

    return {
      'profile': profile,
      'orders': orders,
      'total_orders': (orders as List).length,
      'total_spent': totalSpent,
    };
  }

  static Future<void> updateUserRole(String userId, String newRole) async {
    await _supabase
        .from('profiles')
        .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  // Analytics and Dashboard
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get counts using separate queries
      final productsResponse = await _supabase.from('products').select('id');
      final usersResponse = await _supabase.from('profiles').select('id');
      final ordersResponse = await _supabase.from('orders').select('id');
      final pendingOrdersResponse = await _supabase
          .from('orders')
          .select('id')
          .eq('status', 'pending');

      // Get total revenue
      final revenueResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('status', 'delivered');

      double totalRevenue = 0;
      for (final order in revenueResponse) {
        totalRevenue += (order['total_amount'] as num).toDouble();
      }

      return {
        'total_products': (productsResponse as List).length,
        'total_users': (usersResponse as List).length,
        'total_orders': (ordersResponse as List).length,
        'pending_orders': (pendingOrdersResponse as List).length,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSalesAnalytics({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));

    // Get total sales and orders
    final salesData = await _supabase
        .from('orders')
        .select('total_amount, created_at')
        .eq('status', 'delivered')
        .gte('created_at', startDate.toIso8601String());

    double totalSales = 0;
    int totalOrders = (salesData as List).length;
    Map<String, double> dailySales = {};

    for (final order in salesData) {
      final amount = (order['total_amount'] as num).toDouble();
      totalSales += amount;

      // Group by date
      final date = DateTime.parse(order['created_at'] as String).toIso8601String().split('T')[0];
      dailySales[date] = (dailySales[date] ?? 0) + amount;
    }

    final averageOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0;

    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'average_order_value': averageOrderValue,
      'daily_sales': dailySales,
    };
  }

  // Additional helper methods for your specific schema
  static Future<List<Map<String, dynamic>>> getSubcategories(String category) async {
    final response = await _supabase
        .from('categories')
        .select('*')
        .eq('parent_id', category)
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int days = 30,
    int limit = 10
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    try {
      // Simplified approach - get order items for delivered orders in date range
      final response = await _supabase
          .from('order_items')
          .select('product_id, quantity, products(name, image_url)')
          .gte('created_at', startDate);

      // Group by product_id and sum quantities
      final Map<String, Map<String, dynamic>> productSales = {};

      for (final item in response) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;

        if (productSales.containsKey(productId)) {
          productSales[productId]!['total_quantity'] += quantity;
        } else {
          productSales[productId] = {
            'product_id': productId,
            'total_quantity': quantity,
            'product': item['products'],
          };
        }
      }

      // Convert to list and sort by total_quantity
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      // Log error in debug mode only
      if (kDebugMode) {
        debugPrint('Error getting top selling products: $e');
      }
      return [];
    }
  }

  // Additional utility methods
  static Future<bool> toggleProductStatus(String productId) async {
    try {
      // First get the current status
      final product = await _supabase
          .from('products')
          .select('is_active')
          .eq('id', productId)
          .single();

      final currentStatus = product['is_active'] as bool;

      // Toggle the status
      await _supabase
          .from('products')
          .update({
        'is_active': !currentStatus,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('id', productId);

      return !currentStatus;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> bulkUpdateProductStatus(
      List<String> productIds,
      bool isActive,
      ) async {
    try {
      await _supabase
          .from('products')
          .update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String()
      })
          .inFilter('id', productIds);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getInventoryAlerts({
    int lowStockThreshold = 10,
  }) async {
    try {
      final lowStockProducts = await _supabase
          .from('products')
          .select('id, name, stock_quantity, category')
          .lt('stock_quantity', lowStockThreshold)
          .eq('is_active', true)
          .order('stock_quantity', ascending: true);

      final outOfStockProducts = await _supabase
          .from('products')
          .select('id, name, stock_quantity, category')
          .eq('stock_quantity', 0)
          .eq('is_active', true);

      return {
        'low_stock': lowStockProducts,
        'out_of_stock': outOfStockProducts,
        'low_stock_count': (lowStockProducts as List).length,
        'out_of_stock_count': (outOfStockProducts as List).length,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Low Performing Products Analysis
  static Future<List<Map<String, dynamic>>> getLowPerformingProducts({
    int days = 30,
    int limit = 10,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    try {
      // Get all products
      final allProducts = await _supabase
          .from('products')
          .select('id, name, image_url, price, created_at')
          .eq('is_active', true);

      // Get sales data for the period
      final salesData = await _supabase
          .from('order_items')
          .select('product_id, quantity')
          .gte('created_at', startDate);

      // Create a map of product sales
      final Map<String, int> productSales = {};
      for (final item in salesData) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;
        productSales[productId] = (productSales[productId] ?? 0) + quantity;
      }

      // Find products with low or no sales
      final List<Map<String, dynamic>> lowPerformingProducts = [];

      for (final product in allProducts) {
        final productId = product['id'] as String;
        final salesCount = productSales[productId] ?? 0;

        // Consider products with 2 or fewer sales as low performing
        if (salesCount <= 2) {
          lowPerformingProducts.add({
            'product_id': productId,
            'product_name': product['name'],
            'product_image': product['image_url'],
            'price': product['price'],
            'total_sales': salesCount,
            'created_at': product['created_at'],
          });
        }
      }

      // Sort by sales count (ascending) and then by creation date (newest first)
      lowPerformingProducts.sort((a, b) {
        final salesCompare = (a['total_sales'] as int).compareTo(b['total_sales'] as int);
        if (salesCompare != 0) return salesCompare;

        final dateA = DateTime.tryParse(a['created_at'] ?? '');
        final dateB = DateTime.tryParse(b['created_at'] ?? '');
        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA);
        }
        return 0;
      });

      return lowPerformingProducts.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting low performing products: $e');
      }
      return [];
    }
  }

  // Review Management Methods
  static Future<List<Map<String, dynamic>>> getAllReviews({
    bool? isApproved,
    int limit = 100,
  }) async {
    try {
      PostgrestFilterBuilder query = _supabase
          .from('reviews')
          .select('''
            id, rating, review_text, is_approved, created_at,
            profiles!inner(id, full_name),
            products!inner(id, name, image_url)
          ''');

      if (isApproved != null) {
        query = query.eq('is_approved', isApproved);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> approveReview(String reviewId) async {
    try {
      await _supabase
          .from('reviews')
          .update({
        'is_approved': true,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', reviewId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> rejectReview(String reviewId) async {
    try {
      await _supabase
          .from('reviews')
          .update({
        'is_approved': false,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', reviewId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId);
    } catch (e) {
      rethrow;
    }
  }

  // Additional Analytics Methods
  static Future<Map<String, dynamic>> getReviewsAnalytics() async {
    try {
      final allReviews = await _supabase.from('reviews').select('rating, is_approved');

      int totalReviews = (allReviews as List).length;
      int approvedReviews = 0;
      int pendingReviews = 0;
      double averageRating = 0.0;
      Map<int, int> ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      if (totalReviews > 0) {
        double totalRating = 0.0;

        for (final review in allReviews) {
          final rating = (review['rating'] as num?)?.toInt() ?? 0;
          final isApproved = review['is_approved'] as bool? ?? false;

          if (isApproved) {
            approvedReviews++;
            totalRating += rating;
          } else {
            pendingReviews++;
          }

          if (rating >= 1 && rating <= 5) {
            ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
          }
        }

        if (approvedReviews > 0) {
          averageRating = totalRating / approvedReviews;
        }
      }

      return {
        'total_reviews': totalReviews,
        'approved_reviews': approvedReviews,
        'pending_reviews': pendingReviews,
        'average_rating': averageRating,
        'rating_distribution': ratingDistribution,
      };
    } catch (e) {
      rethrow;
    }
  }
}