import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/supabase_service.dart';
import '../../services/reviews_service.dart';
import '../../components/loading_widget.dart';
import '../../components/empty_state_widget.dart';
import '../../components/price_display.dart';
import '../../components/review_card.dart';
import '../../components/reviews_components.dart';

class ProductDetail extends StatefulWidget {
  final String? productId;

  const ProductDetail({super.key, this.productId});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isAddingToCart = false;
  bool _isTogglingFavorite = false;
  bool _isLoadingReviews = true;

  Map<String, dynamic>? _product;
  bool _isFavorite = false;
  String _error = '';
  int _selectedQuantity = 1;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  // Reviews related
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic> _ratingStats = {
    'total_reviews': 0,
    'average_rating': 0.0,
    'rating_breakdown': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  };
  bool _canUserReview = true;
  bool _userHasReviewed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProduct();
    _loadReviews();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      final productId = widget.productId;
      if (productId == null) {
        throw Exception('Product ID is required');
      }
      final rawProduct = await SupabaseService.getProductById(productId);
      if (rawProduct == null) {
        throw Exception('Product not found');
      }
      final favorites = await SupabaseService.getUserFavorites();
      final canReview = true;
      if (mounted) {
        setState(() {
          _product = _formatProductData(rawProduct);
          _isFavorite = favorites.contains(productId);
          _canUserReview = canReview;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadReviews() async {
    if (widget.productId == null) return;

    try {
      setState(() => _isLoadingReviews = true);

      final reviews = await ReviewsService.getProductReviews(widget.productId!);
      final ratingStats = await ReviewsService.getProductRatingStats(widget.productId!);
      final userReview = await ReviewsService.getUserReviewForProduct(widget.productId!);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _ratingStats = ratingStats;
          _userHasReviewed = userReview != null;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Map<String, dynamic> _formatProductData(Map<String, dynamic> rawProduct) {
    double price = 0.0;
    if (rawProduct['price'] != null) {
      if (rawProduct['price'] is String) {
        price = double.tryParse(rawProduct['price']) ?? 0.0;
      } else if (rawProduct['price'] is num) {
        price = rawProduct['price'].toDouble();
      }
    }

    double? weight;
    if (rawProduct['weight_kg'] != null) {
      if (rawProduct['weight_kg'] is String) {
        weight = double.tryParse(rawProduct['weight_kg']);
      } else if (rawProduct['weight_kg'] is num) {
        weight = rawProduct['weight_kg'].toDouble();
      }
    }

    double? originalPrice;
    if (price > 20) {
      originalPrice = price * 1.2;
    }

    return {
      'id': rawProduct['id'].toString(),
      'name': rawProduct['name'] ?? 'Unknown Product',
      'description': rawProduct['description'] ?? '',
      'price': price,
      'original_price': originalPrice,
      'category': rawProduct['category'] ?? 'Unknown',
      'subcategory': rawProduct['subcategory'] ?? '',
      'brand': rawProduct['brand'] ?? '',
      'image_url': rawProduct['image_url'] ?? '',
      'image_urls': rawProduct['image_urls'] ?? [],
      'stock_quantity': rawProduct['stock_quantity'] ?? 0,
      'is_active': rawProduct['is_active'] ?? true,
      'featured': rawProduct['featured'] ?? false,
      'tags': rawProduct['tags'] ?? [],
      'weight_kg': weight,
      'dimensions_cm': rawProduct['dimensions_cm'] ?? '',
      'age_range': rawProduct['age_range'] ?? '',
      'material': rawProduct['material'] ?? '',
      'safety_certified': rawProduct['safety_certified'] ?? false,
      'is_on_sale': originalPrice != null,
      'is_new': rawProduct['featured'] == true,
    };
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite || _product == null) return;

    try {
      setState(() => _isTogglingFavorite = true);
      await SupabaseService.toggleFavorite(_product!['id']);
      setState(() => _isFavorite = !_isFavorite);
      _showSuccessSnackBar(_isFavorite ? 'Added to favorites' : 'Removed from favorites');
    } catch (e) {
      _showErrorSnackBar('Failed to update favorites');
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _addToCart() async {
    if (_isAddingToCart || _product == null) return;

    try {
      setState(() => _isAddingToCart = true);
      await SupabaseService.addToCart(_product!['id'], quantity: _selectedQuantity);
      _showSuccessSnackBar(
          '${_product!['name']} added to cart ($_selectedQuantity ${_selectedQuantity == 1 ? 'item' : 'items'})');
    } catch (e) {
      _showErrorSnackBar('Failed to add item to cart');
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _showReviewDialog() async {
    final userReview = await ReviewsService.getUserReviewForProduct(widget.productId!);

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedReviewDialog(
        productName: _product!['name'],
        existingReview: userReview,
      ),
    );

    if (result != null && mounted) {
      try {
        setState(() => _isLoadingReviews = true);

        final response = await ReviewsService.submitProductReview(
          productId: widget.productId!,
          rating: result['rating'],
          comment: result['comment'],
          title: result['title'],
          pros: result['pros'],
          cons: result['cons'],
          existingReviewId: userReview?['id'],
        );

        if (response['success']) {
          _showSuccessSnackBar(response['message']);
          await _loadReviews();
        } else {
          _showErrorSnackBar(response['message']);
        }
      } catch (e) {
        _showErrorSnackBar('Failed to submit review. Please try again.');
      } finally {
        if (mounted) setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _markReviewHelpful(String reviewId) async {
    try {
      await ReviewsService.markReviewHelpful(reviewId);
      _showSuccessSnackBar('Thank you for your feedback!');
      _loadReviews();
    } catch (e) {
      _showErrorSnackBar(e.toString().contains('already voted')
          ? 'You have already voted on this review'
          : 'Failed to mark review as helpful');
    }
  }

  Future<void> _markReviewUnhelpful(String reviewId) async {
    try {
      await ReviewsService.markReviewUnhelpful(reviewId);
      _showSuccessSnackBar('Thank you for your feedback!');
      _loadReviews();
    } catch (e) {
      _showErrorSnackBar(e.toString().contains('already voted')
          ? 'You have already voted on this review'
          : 'Failed to mark review as unhelpful');
    }
  }

  Future<void> _reportReview(String reviewId) async {
    final reasons = [
      'Inappropriate content',
      'Spam or fake review',
      'Offensive language',
      'Not relevant to product',
      'Copyright violation',
      'Other',
    ];

    final selectedReason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you reporting this review?'),
            const SizedBox(height: 16),
            ...reasons.map((reason) => ListTile(
              title: Text(reason),
              onTap: () => Navigator.pop(context, reason),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedReason != null) {
      try {
        final response = await ReviewsService.reportReview(
          reviewId: reviewId,
          reason: selectedReason,
        );

        if (response['success']) {
          _showSuccessSnackBar('Review reported successfully');
        } else {
          _showErrorSnackBar(response['message']);
        }
      } catch (e) {
        _showErrorSnackBar('Failed to report review');
      }
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ReviewsService.deleteReview(reviewId);
        if (response['success']) {
          _showSuccessSnackBar('Review deleted successfully');
          _loadReviews();
        } else {
          _showErrorSnackBar(response['message']);
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete review');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _buildBody(),
      bottomNavigationBar: _product != null && !_isLoading && _error.isEmpty
          ? ProductActionButtons(
        isLoading: _isAddingToCart,
        isOutOfStock: (_product!['stock_quantity'] as int? ?? 0) <= 0,
        onAddToCart: _addToCart,
      )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading product details...');
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: EmptyStateWidget(
          message: 'Product not found',
          subtitle: _error,
          icon: Icons.error_outline,
          actionText: 'Go Back',
          onActionPressed: () => Navigator.pop(context),
        ),
      );
    }
    if (_product == null) {
      return const EmptyStateWidget(
        message: 'Product not available',
        subtitle: 'This product is currently unavailable',
        icon: Icons.inventory_2_outlined,
      );
    }
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildAppBar(innerBoxIsScrolled),
          SliverToBoxAdapter(child: _buildImageSection()),
          SliverToBoxAdapter(child: _buildProductInfo()),
          SliverPersistentHeader(
            delegate: _StickyTabBarDelegate(
              child: _buildTabBar(),
              height: 48.0,
            ),
            pinned: true,
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildReviewsTab(),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: innerBoxIsScrolled ? 1 : 0,
      pinned: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: _isTogglingFavorite
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _isTogglingFavorite ? null : _toggleFavorite,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        tabs: [
          const Tab(text: 'DETAILS'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('REVIEWS'),
                if ((_ratingStats['total_reviews'] ?? 0) > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_ratingStats['total_reviews']}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSpecifications(),
          _buildDescription(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Loading reviews...', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRatingsSummary(),
          _buildReviewActions(),
          if (_reviews.isNotEmpty) _buildReviewFilters(),
          if (_reviews.isNotEmpty) _buildReviewsList(),
          if (_reviews.isEmpty) const SizedBox.shrink(), // Remove the _buildEmptyReviews() call
        ],
      ),
    );
  }

  Widget _buildRatingsSummary() {
    if (_ratingStats['total_reviews'] == 0) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Reviews Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Be the first to share your experience!',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final averageRating = (_ratingStats['average_rating'] ?? 0.0).toDouble();
    final totalReviews = _ratingStats['total_reviews'] ?? 0;
    final breakdown = _ratingStats['rating_breakdown'] ?? {};

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Left side - Overall rating
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalReviews ${totalReviews == 1 ? 'Review' : 'Reviews'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right side - Rating breakdown
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = breakdown[rating] ?? 0;
                    final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '$rating',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showReviewDialog,
              icon: Icon(
                _userHasReviewed ? Icons.edit : Icons.rate_review,
                size: 18,
              ),
              label: Text(
                _userHasReviewed ? 'Edit Your Review' : 'Write a Review',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Reviews', true),
            _buildFilterChip('5 Stars', false),
            _buildFilterChip('4 Stars', false),
            _buildFilterChip('3 Stars', false),
            _buildFilterChip('2 Stars', false),
            _buildFilterChip('1 Star', false),
            _buildFilterChip('With Photos', false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
        selected: selected,
        onSelected: (bool value) {
          // Handle filter selection
        },
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppTheme.primary,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }



  Widget _buildReviewsList() {
    return Column(
      children: [
        for (int index = 0; index < _reviews.length; index++)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ReviewCard(
              review: _reviews[index],
              isUserReview: _reviews[index]['user_id'] == SupabaseService.getCurrentUserId(),
              onHelpful: () => _markReviewHelpful(_reviews[index]['id']),
              onUnhelpful: () => _markReviewUnhelpful(_reviews[index]['id']),
              onReport: _reviews[index]['user_id'] == SupabaseService.getCurrentUserId()
                  ? null
                  : () => _reportReview(_reviews[index]['id']),
              onEdit: _reviews[index]['user_id'] == SupabaseService.getCurrentUserId()
                  ? _showReviewDialog
                  : null,
              onDelete: _reviews[index]['user_id'] == SupabaseService.getCurrentUserId()
                  ? () => _deleteReview(_reviews[index]['id'])
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    final images = _getProductImages();

    return Container(
      height: 400,
      width: double.infinity,
      color: Colors.white,
      child: images.isEmpty
          ? _buildPlaceholderImage()
          : Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _imagePageController,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == entry.key
                          ? AppTheme.primary
                          : Colors.grey.shade300,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _getProductImages() {
    if (_product == null) return [];

    List<String> images = [];
    final mainImage = _product!['image_url'] as String?;
    if (mainImage != null && mainImage.isNotEmpty) {
      images.add(mainImage);
    }

    final additionalImages = _product!['image_urls'] as List<dynamic>?;
    if (additionalImages != null && additionalImages.isNotEmpty) {
      images.addAll(additionalImages.cast<String>());
    }

    return images;
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildProductInfo() {
    final product = _product!;
    final averageRating = _ratingStats['average_rating'] ?? 0.0;
    final totalReviews = _ratingStats['total_reviews'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product['name'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PriceDisplay(
                    price: product['price'] ?? 0.0,
                    priceStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    currency: '₦',
                  ),
                  if (product['original_price'] != null)
                    PriceDisplay(
                      price: product['original_price'],
                      priceStyle: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.textSecondary,
                      ),
                      currency: '₦',
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating display
          if (totalReviews > 0) ...[
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < averageRating.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '$averageRating ($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Category and status badges
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product['category'] ?? 'Unknown',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (product['is_on_sale'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'On Sale',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (product['is_new'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (product['safety_certified'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Safety Certified',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Stock status
          Row(
            children: [
              Icon(
                (product['stock_quantity'] ?? 0) > 0 ? Icons.check_circle : Icons.cancel,
                color: (product['stock_quantity'] ?? 0) > 0 ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                (product['stock_quantity'] ?? 0) > 0
                    ? 'In Stock (${product['stock_quantity']} available)'
                    : 'Out of Stock',
                style: TextStyle(
                  color: (product['stock_quantity'] ?? 0) > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quantity selector
          if ((product['stock_quantity'] ?? 0) > 0) _buildQuantitySelector(),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantity:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _selectedQuantity > 1 ? () => setState(() => _selectedQuantity--) : null,
                icon: const Icon(Icons.remove),
                color: AppTheme.primary,
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  _selectedQuantity.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _selectedQuantity < (_product!['stock_quantity'] ?? 0)
                    ? () => setState(() => _selectedQuantity++)
                    : null,
                icon: const Icon(Icons.add),
                color: AppTheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecifications() {
    final product = _product!;
    List<Widget> specs = [];

    if (product['material'] != null && product['material'].toString().isNotEmpty) {
      specs.add(_buildSpecRow('Material', product['material'].toString()));
    }
    if (product['dimensions_cm'] != null && product['dimensions_cm'].toString().isNotEmpty) {
      specs.add(_buildSpecRow('Dimensions', product['dimensions_cm'].toString()));
    }
    if (product['weight_kg'] != null) {
      specs.add(_buildSpecRow('Weight', '${product['weight_kg']} kg'));
    }
    if (product['age_range'] != null && product['age_range'].toString().isNotEmpty) {
      specs.add(_buildSpecRow('Age Range', product['age_range'].toString()));
    }
    if (product['brand'] != null && product['brand'].toString().isNotEmpty) {
      specs.add(_buildSpecRow('Brand', product['brand'].toString()));
    }
    if (product['subcategory'] != null && product['subcategory'].toString().isNotEmpty) {
      specs.add(_buildSpecRow('Subcategory', product['subcategory'].toString()));
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...specs,
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final product = _product!;
    final description = product['description'] as String?;

    if (description == null || description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyTabBarDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class ProductActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool isOutOfStock;
  final VoidCallback onAddToCart;

  const ProductActionButtons({
    super.key,
    required this.isLoading,
    required this.isOutOfStock,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading || isOutOfStock ? null : onAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? Colors.grey : AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  isOutOfStock ? 'OUT OF STOCK' : 'ADD TO CART',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// StarRating widget for displaying ratings
class StarRating extends StatelessWidget {
  final double rating;
  final double starSize;
  final Color color;

  const StarRating({
    Key? key,
    required this.rating,
    this.starSize = 24,
    this.color = Colors.amber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star :
          (index < rating.ceil() ? Icons.star_half : Icons.star_border),
          size: starSize,
          color: color,
        );
      }),
    );
  }
}