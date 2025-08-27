// Fixed product_grid_section.dart - Better aspect ratio and responsive layout
import 'package:flutter/material.dart';
import 'product_card.dart';

class ProductGridSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final Set<String> favoriteProducts;
  final ValueChanged<String> onFavoriteToggle;
  final ValueChanged<Map<String, dynamic>> onAddToCart;
  final ValueChanged<String>? onTap;

  const ProductGridSection({
    super.key,
    required this.title,
    required this.products,
    required this.isLoading,
    required this.favoriteProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding since cards have margin
          child: isLoading
              ? GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7, // Adjusted for better proportions
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
              : products.isEmpty
              ? Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No $title available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
              : LayoutBuilder(
            builder: (context, constraints) {
              // Calculate how many columns based on screen width
              final screenWidth = constraints.maxWidth;
              int crossAxisCount = 2; // Default for mobile
              double childAspectRatio = 0.7; // Default aspect ratio

              if (screenWidth > 600) {
                crossAxisCount = 3; // Tablet
                childAspectRatio = 0.72;
              }
              if (screenWidth > 900) {
                crossAxisCount = 4; // Desktop
                childAspectRatio = 0.75;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final productId = product['id'].toString();
                  return DynamicProductCard(
                    product: product,
                    showAddToCart: true,
                    showDescription: true,
                    isFavorite: favoriteProducts.contains(productId),
                    onFavoriteTap: () => onFavoriteToggle(productId),
                    onAddToCart: () => onAddToCart(product),
                    onTap: onTap != null ? () => onTap!(productId) : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}