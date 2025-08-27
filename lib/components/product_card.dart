// Fixed product_card.dart - Better state management with parent coordination
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/supabase_service.dart';
import '../routes/app_routes.dart';
import 'price_display.dart';

class DynamicProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;
  final bool showDescription;
  final bool showAddToCart;
  final bool isFavorite;

  const DynamicProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCart,
    this.showDescription = true,
    this.showAddToCart = true,
    this.isFavorite = false,
  });

  @override
  State<DynamicProductCard> createState() => _DynamicProductCardState();
}

class _DynamicProductCardState extends State<DynamicProductCard> {
  bool _isAddingToCart = false;
  bool _isTogglingFavorite = false;

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      await SupabaseService.addToCart(widget.product['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      widget.onAddToCart?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _handleFavoriteToggle() async {
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);

    try {
      debugPrint('🔄 ProductCard: Toggling favorite for ${widget.product['id']}');

      // Let the parent handle the state update and UI feedback
      widget.onFavoriteTap?.call();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  void _navigateToProductDetail() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      AppRoutes.navigateToProductDetail(
        context,
        widget.product['id'].toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final stockQuantity = product['stock_quantity'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToProductDetail,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section - Flexible but with constraints
              Expanded(
                flex: 3, // Takes 60% of available height
                child: _buildImageSection(product),
              ),

              // Content section - Flexible
              Expanded(
                flex: 2, // Takes 40% of available height
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Product name - Give it more weight in flexible layout
                      Flexible(
                        flex: 2, // Give more space to product name
                        child: Text(
                          product['name'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Material/Category info - Single line
                      Text(
                        product['material'] != null
                            ? 'Material: ${product['material']}'
                            : product['category'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Spacer to push price and button to bottom
                      const Spacer(),

                      // Price section
                      _buildPriceSection(price),

                      const SizedBox(height: 6),

                      // Add to cart button - Fixed height
                      if (widget.showAddToCart)
                        _buildAddToCartButton(stockQuantity),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(Map<String, dynamic> product) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey[100],
            ),
            child: product['image_url'] != null
                ? ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey, size: 32),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            )
                : const Center(
              child: Icon(Icons.shopping_bag_outlined,
                  color: Colors.grey, size: 32),
            ),
          ),

          // Favorite button - Positioned overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _isTogglingFavorite
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.grey[600],
                  size: 16,
                ),
                onPressed: _isTogglingFavorite ? null : _handleFavoriteToggle,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
              ),
            ),
          ),

          // Featured badge
          if (product['featured'] == true)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Featured',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double price) {
    return PriceDisplay(
      price: price,
      priceStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE67E22),
      ),
      currency: '₦',
    );
  }

  Widget _buildAddToCartButton(int stockQuantity) {
    final isOutOfStock = stockQuantity <= 0;

    return SizedBox(
      width: double.infinity,
      height: 28, // Fixed height for consistency
      child: ElevatedButton(
        onPressed: (isOutOfStock || _isAddingToCart) ? null : _handleAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutOfStock ? Colors.grey : const Color(0xFFE67E22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isAddingToCart
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          isOutOfStock ? 'OUT OF STOCK' : 'ADD TO BAG',
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}