// File: lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  // Categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading categories: $e');
      throw Exception('Failed to load categories');
    }
  }

  // Products
  static Future<List<Map<String, dynamic>>> getProducts({
    bool? featured,
    String? category,
    String? subcategory,
    List<String>? tags,
    int? limit,
    bool? orderByCreatedAt,
  }) async {
    try {
      dynamic query = _client.from('products').select().eq('is_active', true);

      if (featured != null) query = query.eq('featured', featured);
      if (category != null) query = query.eq('category', category);
      if (subcategory != null) query = query.eq('subcategory', subcategory);

      if (tags != null && tags.isNotEmpty) {
        for (final tag in tags) {
          query = query.contains('tags', [tag]);
        }
      }

      if (orderByCreatedAt == true) {
        query = query.order('created_at', ascending: false);
      }

      final response = limit != null ? await query.limit(limit) : await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading products: $e');
      throw Exception('Failed to load products');
    }
  }

  static Future<List<Map<String, dynamic>>> searchProducts(
      String searchQuery,
      ) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('is_active', true)
          .or(
        'name.ilike.%$searchQuery%,description.ilike.%$searchQuery%,category.ilike.%$searchQuery%',
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching products: $e');
      throw Exception('Failed to search products');
    }
  }

  static Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select()
          .eq('id', productId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error loading product: $e');
      throw Exception('Failed to load product');
    }
  }

  // Subcategories + Tags Helpers
  static Future<List<String>> getSubcategories(String category) async {
    try {
      final response = await _client
          .from('products')
          .select('subcategory')
          .eq('category', category)
          .eq('is_active', true);

      final subcategories = <String>{};
      for (final item in response) {
        if (item['subcategory'] != null &&
            item['subcategory'].toString().isNotEmpty) {
          subcategories.add(item['subcategory'].toString());
        }
      }

      return subcategories.toList()..sort();
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      return [];
    }
  }

  static Future<List<String>> getAllTags() async {
    try {
      final response =
      await _client.from('products').select('tags').eq('is_active', true);

      final allTags = <String>{};
      for (final item in response) {
        if (item['tags'] != null && item['tags'] is List) {
          final productTags = item['tags'] as List;
          for (final tag in productTags) {
            if (tag != null && tag.toString().isNotEmpty) {
              allTags.add(tag.toString());
            }
          }
        }
      }

      return allTags.toList()..sort();
    } catch (e) {
      debugPrint('Error loading tags: $e');
      return [];
    }
  }

  // Favorites
// Add this improved version of favorites methods to your SupabaseService class

// Favorites - Improved Version
  static Future<Set<String>> getUserFavorites() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user for favorites');
        return {};
      }

      debugPrint('Loading favorites for user: ${user.id}');

      final response = await _client
          .from('favorites')
          .select('product_id')
          .eq('user_id', user.id);

      debugPrint('Raw favorites response: $response');

      final favoriteIds = response
          .map<String>((fav) => fav['product_id'].toString())
          .toSet();

      debugPrint('Parsed favorite IDs: $favoriteIds');
      return favoriteIds;
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getFavoriteProducts() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user for favorite products');
        return [];
      }

      debugPrint('Loading favorite products for user: ${user.id}');

      // Use a left join to get all favorites, even if product might be missing
      final response = await _client
          .from('favorites')
          .select('''
          product_id,
          products (
            id,
            name,
            price,
            image_url,
            category,
            description,
            stock_quantity,
            is_active,
            material,
            dimensions_cm,
            weight_kg,
            age_range,
            safety_certified,
            brand,
            featured
          )
        ''')
          .eq('user_id', user.id);

      debugPrint('Raw favorite products response: $response');

      // Filter out any favorites where the product no longer exists or is inactive
      final favoriteProducts = response
          .where((item) =>
      item['products'] != null &&
          item['products']['is_active'] == true)
          .map<Map<String, dynamic>>((item) => item['products'])
          .toList();

      debugPrint('Filtered favorite products: ${favoriteProducts.length} products');
      return favoriteProducts;
    } catch (e) {
      debugPrint('Error loading favorite products: $e');
      throw Exception('Failed to load favorite products: $e');
    }
  }

  static Future<void> toggleFavorite(String productId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('❌ toggleFavorite: No authenticated user');
      throw Exception('User not authenticated');
    }

    debugPrint('🔄 toggleFavorite: Starting for productId: $productId, userId: ${user.id}');

    try {
      // Check if favorite already exists
      debugPrint('🔍 Checking if favorite exists...');
      final existingFav = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      debugPrint('📋 Existing favorite result: $existingFav');

      if (existingFav != null) {
        // Remove from favorites
        debugPrint('🗑️ Removing from favorites...');
        final deleteResult = await _client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId)
            .select();

        debugPrint('✅ Delete result: $deleteResult');
      } else {
        // Add to favorites
        debugPrint('➕ Adding to favorites...');
        final insertData = {
          'user_id': user.id,
          'product_id': productId,
          'created_at': DateTime.now().toIso8601String(),
        };
        debugPrint('📝 Insert data: $insertData');

        final insertResult = await _client
            .from('favorites')
            .insert(insertData)
            .select();

        debugPrint('✅ Insert result: $insertResult');
      }

      debugPrint('🎉 toggleFavorite completed successfully');
    } catch (e) {
      debugPrint('❌ toggleFavorite error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      throw Exception('Failed to update favorites: $e');
    }
  }

// Add this method to check if a specific product is favorited
  static Future<bool> isProductFavorited(String productId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if product is favorited: $e');
      return false;
    }
  }

  // Cart Management Methods
  static Future<void> addToCart(String productId, {int quantity = 1}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final existingItem = await _client
          .from('cart')
          .select('id, quantity')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItem != null) {
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        await _client
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingItem['id']);
      } else {
        await _client.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': quantity,
        });
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      throw Exception('Failed to add item to cart');
    }
  }

  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('cart')
          .select('''
            id,
            quantity,
            created_at,
            products!inner (
              id,
              name,
              price,
              image_url,
              category,
              description,
              stock_quantity,
              is_active
            )
          ''')
          .eq('user_id', user.id)
          .eq('products.is_active', true)
          .order('created_at', ascending: false);

      return response
          .map<Map<String, dynamic>>(
            (item) => {
          'id': item['id'],
          'quantity': item['quantity'],
          'created_at': item['created_at'],
          'product': item['products'],
        },
      )
          .toList();
    } catch (e) {
      debugPrint('Error loading cart items: $e');
      throw Exception('Failed to load cart items');
    }
  }

  static Future<int> getCartItemCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client
          .from('cart')
          .select('quantity')
          .eq('user_id', user.id);

      return response.fold<int>(
        0,
            (sum, item) => sum + (item['quantity'] as int? ?? 0),
      );
    } catch (e) {
      debugPrint('Error loading cart count: $e');
      return 0;
    }
  }

  static Future<void> updateCartItemQuantity(
      String cartItemId,
      int newQuantity,
      ) async {
    try {
      await _client
          .from('cart')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId);
    } catch (e) {
      debugPrint('Error updating cart item quantity: $e');
      throw Exception('Failed to update cart item quantity');
    }
  }

  static Future<void> updateCartItemColor(
      String cartItemId,
      String colorValue,
      ) async {
    try {
      debugPrint('Color update not supported in current schema');
    } catch (e) {
      debugPrint('Error updating cart item color: $e');
      throw Exception('Failed to update cart item color');
    }
  }

  static Future<void> removeFromCart(String cartItemId) async {
    try {
      await _client.from('cart').delete().eq('id', cartItemId);
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      throw Exception('Failed to remove item from cart');
    }
  }

  static Future<void> clearCart() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _client.from('cart').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      throw Exception('Failed to clear cart');
    }
  }

  // Reviews and Ratings Methods
  // static Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
  //   try {
  //     final response = await _client
  //         .from('reviews')
  //         .select('''
  //           id,
  //           rating,
  //           comment,
  //           title,
  //           pros,
  //           cons,
  //           helpful_count,
  //           unhelpful_count,
  //           created_at,
  //           profiles!reviews_user_id_fkey (
  //             id,
  //             full_name,
  //             avatar_url
  //           )
  //         ''')
  //         .eq('product_id', productId)
  //         .order('created_at', ascending: false);
  //
  //     return response.map<Map<String, dynamic>>((review) => {
  //       'id': review['id'],
  //       'rating': review['rating'],
  //       'comment': review['comment'],
  //       'title': review['title'],
  //       'pros': review['pros'],
  //       'cons': review['cons'],
  //       'helpful_count': review['helpful_count'] ?? 0,
  //       'unhelpful_count': review['unhelpful_count'] ?? 0,
  //       'created_at': _formatDate(review['created_at']),
  //       'user_name': review['profiles']?['full_name'] ?? 'Anonymous',
  //       'avatar_url': review['profiles']?['avatar_url'],
  //     }).toList();
  //   } catch (e) {
  //     debugPrint('Error loading reviews: $e');
  //     return [];
  //   }
  // }
  //
  // static Future<Map<String, dynamic>> getProductRatings(String productId) async {
  //   try {
  //     final response = await _client
  //         .from('reviews')
  //         .select('rating')
  //         .eq('product_id', productId);
  //
  //     if (response.isEmpty) {
  //       return {'average': 0.0, 'count': 0};
  //     }
  //
  //     final ratings = response.map<double>((r) => (r['rating'] as num).toDouble()).toList();
  //     final average = ratings.reduce((a, b) => a + b) / ratings.length;
  //
  //     return {
  //       'average': double.parse(average.toStringAsFixed(1)),
  //       'count': ratings.length,
  //     };
  //   } catch (e) {
  //     debugPrint('Error loading ratings: $e');
  //     return {'average': 0.0, 'count': 0};
  //   }
  // }
  //
  // static Future<Map<String, dynamic>> submitProductReview(
  //     String productId,
  //     double rating,
  //     String comment, {
  //       String? title,
  //       String? pros,
  //       String? cons,
  //     }) async {
  //   final user = _client.auth.currentUser;
  //   if (user == null) {
  //     return {'success': false, 'message': 'User not authenticated'};
  //   }
  //
  //   try {
  //     // Check if user already reviewed this product
  //     final existingReview = await _client
  //         .from('reviews')
  //         .select('id')
  //         .eq('user_id', user.id)
  //         .eq('product_id', productId)
  //         .maybeSingle();
  //
  //     final reviewData = {
  //       'product_id': productId,
  //       'user_id': user.id,
  //       'rating': rating.toInt(),
  //       'comment': comment.trim(),
  //       'title': title?.trim(),
  //       'pros': pros?.trim(),
  //       'cons': cons?.trim(),
  //       'is_verified_purchase': false, // Add this field
  //       'updated_at': DateTime.now().toIso8601String(),
  //     };
  //
  //     if (existingReview != null) {
  //       // Update existing review
  //       await _client
  //           .from('reviews')
  //           .update(reviewData)
  //           .eq('id', existingReview['id']);
  //
  //       return {
  //         'success': true,
  //         'message': 'Review updated successfully',
  //       };
  //     } else {
  //       // Create new review
  //       reviewData['created_at'] = DateTime.now().toIso8601String();
  //       reviewData['helpful_count'] = 0;
  //       reviewData['unhelpful_count'] = 0;
  //       reviewData['reply_count'] = 0;
  //
  //       await _client.from('reviews').insert(reviewData);
  //
  //       return {
  //         'success': true,
  //         'message': 'Review submitted successfully',
  //       };
  //     }
  //   } catch (e) {
  //     debugPrint('Error submitting review: $e');
  //     return {
  //       'success': false,
  //       'message': 'Failed to submit review: ${e.toString()}',
  //     };
  //   }
  // }
  //
  // // Get user's existing review for a product
  // static Future<Map<String, dynamic>?> getUserReviewForProduct(String productId) async {
  //   try {
  //     final user = _client.auth.currentUser;
  //     if (user == null) return null;
  //
  //     final response = await _client
  //         .from('reviews')
  //         .select('*')
  //         .eq('product_id', productId)
  //         .eq('user_id', user.id)
  //         .maybeSingle();
  //
  //     return response;
  //   } catch (e) {
  //     debugPrint('Error fetching user review: $e');
  //     return null;
  //   }
  // }
  //
  // // Mark a review as helpful
  // static Future<void> markReviewHelpful(String reviewId) async {
  //   try {
  //     final user = _client.auth.currentUser;
  //     if (user == null) throw Exception('User not authenticated');
  //
  //     // Check if user already voted on this review
  //     final existingVote = await _client
  //         .from('review_votes')
  //         .select('id')
  //         .eq('review_id', reviewId)
  //         .eq('user_id', user.id)
  //         .maybeSingle();
  //
  //     if (existingVote != null) {
  //       throw Exception('You have already voted on this review');
  //     }
  //
  //     // Add vote record
  //     await _client.from('review_votes').insert({
  //       'review_id': reviewId,
  //       'user_id': user.id,
  //       'vote_type': 'helpful',
  //       'created_at': DateTime.now().toIso8601String(),
  //     });
  //
  //     // Update helpful count
  //     await _client.rpc('increment_helpful_count', params: {
  //       'review_id': reviewId
  //     });
  //   } catch (e) {
  //     debugPrint('Error marking review helpful: $e');
  //     throw Exception('Failed to mark review as helpful: $e');
  //   }
  // }
  //
  // // Mark a review as unhelpful
  // static Future<void> markReviewUnhelpful(String reviewId) async {
  //   try {
  //     final user = _client.auth.currentUser;
  //     if (user == null) throw Exception('User not authenticated');
  //
  //     // Check if user already voted on this review
  //     final existingVote = await _client
  //         .from('review_votes')
  //         .select('id')
  //         .eq('review_id', reviewId)
  //         .eq('user_id', user.id)
  //         .maybeSingle();
  //
  //     if (existingVote != null) {
  //       throw Exception('You have already voted on this review');
  //     }
  //
  //     // Add vote record
  //     await _client.from('review_votes').insert({
  //       'review_id': reviewId,
  //       'user_id': user.id,
  //       'vote_type': 'unhelpful',
  //       'created_at': DateTime.now().toIso8601String(),
  //     });
  //
  //     // Update unhelpful count
  //     await _client.rpc('increment_unhelpful_count', params: {
  //       'review_id': reviewId
  //     });
  //   } catch (e) {
  //     debugPrint('Error marking review unhelpful: $e');
  //     throw Exception('Failed to mark review as unhelpful: $e');
  //   }
  // }
  //
  // // Delete a review (only by the review author)
  // static Future<Map<String, dynamic>> deleteReview(String reviewId) async {
  //   try {
  //     final user = _client.auth.currentUser;
  //     if (user == null) {
  //       return {'success': false, 'message': 'User not authenticated'};
  //     }
  //
  //     final response = await _client
  //         .from('reviews')
  //         .delete()
  //         .eq('id', reviewId)
  //         .eq('user_id', user.id) // Security check
  //         .select();
  //
  //     if (response.isNotEmpty) {
  //       return {'success': true, 'message': 'Review deleted successfully'};
  //     } else {
  //       return {'success': false, 'message': 'Review not found or unauthorized'};
  //     }
  //   } catch (e) {
  //     debugPrint('Error deleting review: $e');
  //     return {
  //       'success': false,
  //       'message': 'Failed to delete review: ${e.toString()}',
  //     };
  //   }
  // }

  // Orders Management
  static Future<Map<String, dynamic>> createOrder(
      List<Map<String, dynamic>> cartItems,
      Map<String, dynamic> shippingDetails,
      Map<String, dynamic> paymentDetails,
      ) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Calculate amounts
      final subtotal = cartItems.fold<double>(
        0.0,
            (sum, item) => sum + (item['quantity'] * item['product']['price']),
      );
      final shippingAmount = subtotal > 50 ? 0.0 : 5.0;
      final taxAmount = subtotal * 0.075; // 7.5% tax
      final totalAmount = subtotal + shippingAmount + taxAmount;

      // Generate order number
      final orderNumber = 'BSH-${DateTime.now().millisecondsSinceEpoch}';

      // Create order
      final orderResponse = await _client.from('orders').insert({
        'user_id': user.id,
        'order_number': orderNumber,
        'status': 'pending',
        'total_amount': totalAmount,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'shipping_amount': shippingAmount,
        'discount_amount': 0.0,
        'shipping_address': shippingDetails,
        'billing_address': shippingDetails, // Using same as shipping for now
        'payment_method': paymentDetails['method'],
        'payment_status': paymentDetails['method'] == 'cash' ? 'pending' : 'paid',
        'tracking_number': _generateTrackingNumber(),
        'estimated_delivery': DateTime.now().add(Duration(days: 3)),
      }).select().single();

      // Create order items
      final orderItems = cartItems.map((item) => {
        'order_id': orderResponse['id'],
        'product_id': item['product']['id'],
        'quantity': item['quantity'],
        'unit_price': item['product']['price'],
        'total_price': item['quantity'] * item['product']['price'],
        'product_name': item['product']['name'],
        'product_image': item['product']['image_url'],
      }).toList();

      await _client.from('order_items').insert(orderItems);

      // Clear cart after successful order
      await clearCart();

      return {
        'success': true,
        'order_id': orderResponse['id'],
        'order_number': orderNumber,
        'message': 'Order placed successfully',
      };
    } catch (e) {
      debugPrint('Error creating order: $e');
      return {
        'success': false,
        'message': 'Failed to place order: $e',
      };
    }
  }

  static String _generateTrackingNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 10000).abs().toString().padLeft(4, '0');
    return 'TRK$random';
  }

  static Future<List<Map<String, dynamic>>> getUserOrdersDetailed() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('orders')
          .select('''
            id,
            order_number,
            status,
            total_amount,
            subtotal,
            tax_amount,
            shipping_amount,
            payment_method,
            payment_status,
            tracking_number,
            estimated_delivery,
            delivered_at,
            created_at,
            order_items (
              id,
              quantity,
              unit_price,
              total_price,
              product_name,
              product_image
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading detailed orders: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              *
            )
          ''')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error loading order: $e');
      return null;
    }
  }

  static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
        if (newStatus == 'delivered') 'delivered_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> trackOrder(String trackingNumber) async {
    try {
      final response = await _client
          .from('orders')
          .select('''
            id,
            order_number,
            status,
            tracking_number,
            estimated_delivery,
            delivered_at,
            created_at
          ''')
          .eq('tracking_number', trackingNumber)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error tracking order: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getUserOrderStats() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return {'total_orders': 0, 'total_spent': 0.0};

      final response = await _client
          .from('orders')
          .select('total_amount')
          .eq('user_id', user.id);

      final totalOrders = response.length;
      final totalSpent = response.fold<double>(
        0.0,
            (sum, order) => sum + (order['total_amount'] ?? 0.0),
      );

      return {
        'total_orders': totalOrders,
        'total_spent': totalSpent,
      };
    } catch (e) {
      debugPrint('Error loading order stats: $e');
      return {'total_orders': 0, 'total_spent': 0.0};
    }
  }

  static Future<bool> cancelOrder(String orderId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final order = await _client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (order == null || order['status'] != 'pending') {
        return false;
      }

      await _client
          .from('orders')
          .update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId);

      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  static Future<int> getUserOrderCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client
          .from('orders')
          .select('id')
          .eq('user_id', user.id);

      return response.length;
    } catch (e) {
      debugPrint('Error loading order count: $e');
      return 0;
    }
  }

  // FEEDBACK MANAGEMENT METHODS

  /// Submit user feedback to the database
  static Future<void> submitFeedback(String subject, String message) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('feedback').insert({
        'user_id': user.id,
        'subject': subject.trim(),
        'message': message.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: ${e.toString()}');
    }
  }

  /// Get user's feedback history
  static Future<List<Map<String, dynamic>>> getUserFeedback() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('feedback')
          .select('id, subject, message, status, created_at, updated_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map<Map<String, dynamic>>((feedback) => {
        'id': feedback['id'],
        'subject': feedback['subject'],
        'message': feedback['message'],
        'status': feedback['status'],
        'created_at': _formatDate(feedback['created_at']),
        'updated_at': feedback['updated_at'] != null
            ? _formatDate(feedback['updated_at'])
            : null,
      }).toList();
    } catch (e) {
      debugPrint('Error loading user feedback: $e');
      return [];
    }
  }

  /// Get feedback by ID (for viewing details)
  static Future<Map<String, dynamic>?> getFeedbackById(String feedbackId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('feedback')
          .select('*')
          .eq('id', feedbackId)
          .eq('user_id', user.id) // Ensure user can only access their own feedback
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error loading feedback details: $e');
      return null;
    }
  }

  /// Update feedback status (mainly for admin use, but included for completeness)
  static Future<bool> updateFeedbackStatus(String feedbackId, String newStatus) async {
    try {
      await _client
          .from('feedback')
          .update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', feedbackId);
      return true;
    } catch (e) {
      debugPrint('Error updating feedback status: $e');
      return false;
    }
  }

  // Helper method to format products for display
  static Map<String, dynamic> formatProductForDisplay(
      Map<String, dynamic> product, {
        bool isNew = false,
      }) {
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = price > 20 ? price * 1.2 : null;

    return {
      'id': product['id'].toString(),
      'name': product['name'] ?? 'Unknown Product',
      'price': price,
      'original_price': originalPrice,
      'image_url': product['image_url'],
      'rating': 4.5,
      'reviews_count': 0,
      'is_on_sale': originalPrice != null,
      'is_new': isNew,
      'category': product['category'] ?? 'Unknown',
      'description': product['description'],
      'stock_quantity': product['stock_quantity'] ?? 0,
      'material': product['material'],
      'dimensions_cm': product['dimensions_cm'],
      'weight_kg': product['weight_kg'],
      'age_range': product['age_range'],
      'safety_certified': product['safety_certified'],
      'brand': product['brand'],
      'featured': product['featured'],
    };
  }

  // Helper method to format dates
  static String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to get category icon
  static String getCategoryIcon(String categoryName) {
    final icons = {
      'Diapers & Wipes': '🍼',
      'Baby Food': '🍯',
      'Clothing': '👶',
      'Toys': '🧸',
      'Bath & Care': '🛁',
      'Strollers & Gear': '🚼',
      'Nursery': '🏠',
      'Health & Safety': '🛡️',
      'Tableware': '🍽️',
      'Accessories': '👜',
    };
    return icons[categoryName] ?? '👶';
  }

  // Helper method to get category color
  static String getCategoryColor(String categoryName) {
    final colors = {
      'Diapers & Wipes': '#FFE5B4',
      'Baby Food': '#FFD1DC',
      'Clothing': '#E0E6FF',
      'Toys': '#E5F3FF',
      'Bath & Care': '#E8F5E8',
      'Strollers & Gear': '#FFF0E5',
      'Nursery': '#F0E6FF',
      'Health & Safety': '#E6F3FF',
      'Tableware': '#E5F3E0',
      'Accessories': '#F5E6D3',
    };
    return colors[categoryName] ?? '#FFE5B4';
  }

  // Additional Methods
  static Future<void> clearUserCart() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client
          .from('cart')
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              products (
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items (
              *,
              products (
                id,
                name,
                image_url,
                category
              )
            )
          ''')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching order details: $e');
      return null;
    }
  }

  static Future<bool> saveShippingAddress(Map<String, dynamic> address) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('user_addresses')
          .upsert({
        'user_id': user.id,
        'address_type': 'shipping',
        'first_name': address['first_name'],
        'last_name': address['last_name'],
        'street_address': address['address'],
        'city': address['city'],
        'state': address['state'],
        'postal_code': address['postal_code'],
        'phone': address['phone'],
        'is_default': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error saving shipping address: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSavedAddresses() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_default', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching saved addresses: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> validateCoupon(String couponCode) async {
    try {
      final response = await _client
          .from('coupons')
          .select()
          .eq('code', couponCode.toUpperCase())
          .eq('is_active', true)
          .gte('valid_until', DateTime.now().toIso8601String())
          .single();

      return response;
    } catch (e) {
      debugPrint('Invalid or expired coupon: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
    required String orderId,
  }) async {
    try {
      if (paymentMethod == 'cash') {
        return {
          'success': true,
          'message': 'Cash on delivery order confirmed',
        };
      }

      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'message': 'Payment processed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment processing failed: ${e.toString()}',
      };
    }
  }
}