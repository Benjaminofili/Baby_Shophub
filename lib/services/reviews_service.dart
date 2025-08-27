import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsService {
  static final _supabase = Supabase.instance.client;

  /// Get all reviews for a specific product with user profile data
  static Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('''
            id, rating, comment, helpful_count, unhelpful_count, 
            created_at, updated_at, title, pros, cons, images, user_id,
            profiles (full_name, avatar_url)
          ''')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      // Transform the data to flatten the profiles structure
      return response.map<Map<String, dynamic>>((review) {
        final profiles = review['profiles'] as Map<String, dynamic>?;

        return {
          'id': review['id'],
          'rating': review['rating'],
          'comment': review['comment'] ?? '',
          'title': review['title'] ?? '',
          'pros': review['pros'] ?? '',
          'cons': review['cons'] ?? '',
          'helpful_count': review['helpful_count'] ?? 0,
          'unhelpful_count': review['unhelpful_count'] ?? 0,
          'created_at': review['created_at'],
          'updated_at': review['updated_at'],
          'user_id': review['user_id'],
          'images': review['images'] ?? [],
          // Flatten profile data
          'user_name': profiles?['full_name'] ?? 'Anonymous',
          'avatar_url': profiles?['avatar_url'],
          // Add profiles key for backward compatibility
          'profiles': profiles,
        };
      }).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Get rating statistics for a product
  static Future<Map<String, dynamic>> getProductRatingStats(String productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('product_id', productId);

      final reviews = List<Map<String, dynamic>>.from(response);
      final totalReviews = reviews.length;

      if (totalReviews == 0) {
        return {
          'total_reviews': 0,
          'average_rating': 0.0,
          'rating_breakdown': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      final averageRating = reviews.fold<double>(
          0.0,
              (sum, review) => sum + ((review['rating'] as int?) ?? 0).toDouble()
      ) / totalReviews;

      final ratingBreakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (var review in reviews) {
        final rating = review['rating'] as int? ?? 0;
        if (rating >= 1 && rating <= 5) {
          ratingBreakdown[rating] = (ratingBreakdown[rating] ?? 0) + 1;
        }
      }

      return {
        'total_reviews': totalReviews,
        'average_rating': double.parse(averageRating.toStringAsFixed(1)),
        'rating_breakdown': ratingBreakdown,
      };
    } catch (e) {
      print('Error fetching rating stats: $e');
      throw Exception('Failed to fetch rating stats: $e');
    }
  }

  /// Submit or update a product review
  static Future<Map<String, dynamic>> submitProductReview({
    required String productId,
    required int rating,
    required String comment,
    String? title,
    String? pros,
    String? cons,
    List<String>? images,
    String? existingReviewId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        return {'success': false, 'message': 'Rating must be between 1 and 5'};
      }

      // Validate comment
      if (comment.trim().isEmpty) {
        return {'success': false, 'message': 'Review comment is required'};
      }

      final reviewData = {
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'comment': comment.trim(),
        'title': title?.trim(),
        'pros': pros?.trim(),
        'cons': cons?.trim(),
        'images': images ?? [],
        'updated_at': DateTime.now().toIso8601String(),
      };

      dynamic response;

      if (existingReviewId != null) {
        // Update existing review
        response = await _supabase
            .from('reviews')
            .update(reviewData)
            .eq('id', existingReviewId)
            .eq('user_id', userId)
            .select();
      } else {
        // Check if user already reviewed this product
        final existingReview = await _supabase
            .from('reviews')
            .select('id')
            .eq('product_id', productId)
            .eq('user_id', userId)
            .maybeSingle();

        if (existingReview != null) {
          return {'success': false, 'message': 'You have already reviewed this product. Edit your existing review instead.'};
        }

        // Create new review
        reviewData['created_at'] = DateTime.now().toIso8601String();
        reviewData['helpful_count'] = 0;
        reviewData['unhelpful_count'] = 0;

        response = await _supabase
            .from('reviews')
            .insert(reviewData)
            .select();
      }

      if (response != null && response.isNotEmpty) {
        return {
          'success': true,
          'message': existingReviewId != null
              ? 'Review updated successfully'
              : 'Review submitted successfully',
          'review': response[0],
        };
      } else {
        return {'success': false, 'message': 'Failed to save review'};
      }
    } catch (e) {
      print('Error submitting review: $e');
      return {
        'success': false,
        'message': 'Failed to submit review: ${e.toString()}',
      };
    }
  }

  /// Get user's existing review for a product
  static Future<Map<String, dynamic>?> getUserReviewForProduct(String productId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('reviews')
          .select('*')
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching user review: $e');
      return null;
    }
  }

  /// Mark a review as helpful
  static Future<void> markReviewHelpful(String reviewId) async {
  try {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  // Check if user already marked this review
  final existingVote = await _supabase
      .from('review_votes')
      .select('id, vote_type')
      .eq('review_id', reviewId)
      .eq('user_id', userId)
      .maybeSingle();

  if (existingVote != null) {
  if (existingVote['vote_type'] == 'helpful') {
  throw Exception('You have already marked this review as helpful');
  } else {
  // Update from unhelpful to helpful
  await _supabase
      .from('review_votes')
      .update({'vote_type': 'helpful'})
      .eq('id', existingVote['id']);

  // Get current counts and update them
  final review = await _supabase
      .from('reviews')
      .select('helpful_count, unhelpful_count')
      .eq('id', reviewId)
      .single();

  final currentHelpful = review['helpful_count'] as int;
  final currentUnhelpful = review['unhelpful_count'] as int;

  await _supabase
      .from('reviews')
      .update({
  'helpful_count': currentHelpful + 1,
  'unhelpful_count': currentUnhelpful - 1
  })
      .eq('id', reviewId);
  return;
  }
  }

  // Add vote record
  await _supabase.from('review_votes').insert({
  'review_id': reviewId,
  'user_id': userId,
  'vote_type': 'helpful',
  'created_at': DateTime.now().toIso8601String(),
  });

  // Get current helpful count and update it
  final review = await _supabase
      .from('reviews')
      .select('helpful_count')
      .eq('id', reviewId)
      .single();

  final currentHelpful = review['helpful_count'] as int;

  await _supabase
      .from('reviews')
      .update({'helpful_count': currentHelpful + 1})
      .eq('id', reviewId);
  } catch (e) {
  print('Error marking review helpful: $e');
  throw Exception('Failed to mark review as helpful: $e');
  }
  }

  /// Mark a review as unhelpful
  static Future<void> markReviewUnhelpful(String reviewId) async {
  try {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('User not authenticated');

  // Check if user already marked this review
  final existingVote = await _supabase
      .from('review_votes')
      .select('id, vote_type')
      .eq('review_id', reviewId)
      .eq('user_id', userId)
      .maybeSingle();

  if (existingVote != null) {
  if (existingVote['vote_type'] == 'unhelpful') {
  throw Exception('You have already marked this review as unhelpful');
  } else {
  // Update from helpful to unhelpful
  await _supabase
      .from('review_votes')
      .update({'vote_type': 'unhelpful'})
      .eq('id', existingVote['id']);

  // Get current counts and update them
  final review = await _supabase
      .from('reviews')
      .select('helpful_count, unhelpful_count')
      .eq('id', reviewId)
      .single();

  final currentHelpful = review['helpful_count'] as int;
  final currentUnhelpful = review['unhelpful_count'] as int;

  await _supabase
      .from('reviews')
      .update({
  'helpful_count': currentHelpful - 1,
  'unhelpful_count': currentUnhelpful + 1
  })
      .eq('id', reviewId);
  return;
  }
  }

  // Add vote record
  await _supabase.from('review_votes').insert({
  'review_id': reviewId,
  'user_id': userId,
  'vote_type': 'unhelpful',
  'created_at': DateTime.now().toIso8601String(),
  });

  // Get current unhelpful count and update it
  final review = await _supabase
      .from('reviews')
      .select('unhelpful_count')
      .eq('id', reviewId)
      .single();

  final currentUnhelpful = review['unhelpful_count'] as int;

  await _supabase
      .from('reviews')
      .update({'unhelpful_count': currentUnhelpful + 1})
      .eq('id', reviewId);
  } catch (e) {
  print('Error marking review unhelpful: $e');
  throw Exception('Failed to mark review as unhelpful: $e');
  }
  }


  /// Delete a review (only by the review author)
  static Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', userId)
          .select();

      if (response.isNotEmpty) {
        return {'success': true, 'message': 'Review deleted successfully'};
      } else {
        return {'success': false, 'message': 'Review not found or unauthorized'};
      }
    } catch (e) {
      print('Error deleting review: $e');
      return {
        'success': false,
        'message': 'Failed to delete review: ${e.toString()}',
      };
    }
  }

  /// Report a review
  static Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Check if user already reported this review
      final existingReport = await _supabase
          .from('review_reports')
          .select('id')
          .eq('review_id', reviewId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingReport != null) {
        return {'success': false, 'message': 'You have already reported this review'};
      }

      // Create report
      await _supabase.from('review_reports').insert({
        'review_id': reviewId,
        'user_id': userId,
        'reason': reason,
        'additional_info': additionalInfo,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return {'success': true, 'message': 'Review reported successfully'};
    } catch (e) {
      print('Error reporting review: $e');
      return {
        'success': false,
        'message': 'Failed to report review: ${e.toString()}',
      };
    }
  }

  /// Helper method to format dates
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error formatting date: $e');
      return dateString;
    }
  }
}