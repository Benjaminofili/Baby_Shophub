// Updated Home.dart - Remove the bottom navigation and update navigation logic
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../components/app_header.dart';
import '../../components/search_section.dart';
import '../../components/offer_section.dart';
import '../../components/categories_section.dart';
import '../../components/product_grid_section.dart';
import '../../components/product_card.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_service.dart';

class HomePageDemo extends StatefulWidget {
  const HomePageDemo({super.key});

  @override
  State<HomePageDemo> createState() => _HomePageDemoState();
}

class _HomePageDemoState extends State<HomePageDemo> {
  final TextEditingController _searchController = TextEditingController();

  // Loading states
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  bool _isLoadingFavorites = true;

  // Data from Supabase
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  List<Map<String, dynamic>> _newArrivals = [];
  Set<String> _favoriteProducts = {};
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCategories(),
      _loadProducts(),
      _loadFavorites(),
      _loadCartCount(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoadingCategories = true);

      final categories = await SupabaseService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categories
              .map<Map<String, dynamic>>(
                (category) => {
                  'id': category['id'],
                  'name': category['name'],
                  'icon': SupabaseService.getCategoryIcon(category['name']),
                  'color': SupabaseService.getCategoryColor(category['name']),
                },
              )
              .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        _showErrorSnackBar('Failed to load categories');
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoadingProducts = true);

      final featuredProducts = await SupabaseService.getProducts(
        featured: true,
        limit: 6,
      );

      final newArrivals = await SupabaseService.getProducts(
        orderByCreatedAt: true,
        limit: 4,
      );

      if (mounted) {
        setState(() {
          _featuredProducts = featuredProducts
              .map(
                (product) => SupabaseService.formatProductForDisplay(product),
              )
              .toList();
          _newArrivals = newArrivals
              .map(
                (product) => SupabaseService.formatProductForDisplay(
                  product,
                  isNew: true,
                ),
              )
              .toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        _showErrorSnackBar('Failed to load products');
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() => _isLoadingFavorites = true);

      final favorites = await SupabaseService.getUserFavorites();

      if (mounted) {
        setState(() {
          _favoriteProducts = favorites;
          _isLoadingFavorites = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final count = await SupabaseService.getCartItemCount();
      if (mounted) {
        setState(() => _cartItemCount = count);
      }
    } catch (e) {
      debugPrint('Error loading cart count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          AppHeader(
            title: 'BabyShopHub',
            subtitle: 'Everything for your little one',
            onSearchTap: _navigateToSearch,
            onCartTap: _navigateToCart,
            onProfileTap: _navigateToProfile,
            onLogoutTap: _logoutUser,
            cartItemCount: _cartItemCount,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchSection(
                      controller: _searchController,
                      onSubmitted: _handleSearch,
                      onTap: _navigateToSearch,
                    ),
                    OfferSection(
                      title: '🎉 Special Offer!',
                      description:
                          'Get 30% off on all baby clothing items. Limited time offer!',
                      buttonText: 'Shop Now',
                      onButtonPressed: () =>
                          _navigateToCategoryProducts('Clothing'),
                    ),
                    CategoriesSection(
                      categories: _categories,
                      isLoading: _isLoadingCategories,
                      onTap: _navigateToCategoryProducts,
                    ),
                    ProductGridSection(
                      title: 'Featured Products',
                      products: _featuredProducts,
                      isLoading: _isLoadingProducts,
                      favoriteProducts: _favoriteProducts,
                      onFavoriteToggle: _toggleFavorite,
                      onAddToCart: _addToCart,
                      onTap: _navigateToProductDetail,
                    ),
                    ProductGridSection(
                      title: 'New Arrivals',
                      products: _newArrivals,
                      isLoading: _isLoadingProducts,
                      favoriteProducts: _favoriteProducts,
                      onFavoriteToggle: _toggleFavorite,
                      onAddToCart: _addToCart,
                      onTap: _navigateToProductDetail,
                    ),
                    const SizedBox(height: 100), // Extra space for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.pushNamed(
      context,
      '/search',
      arguments: {'query': _searchController.text},
    );
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) {
      _showErrorSnackBar('Please enter a search term');
      return;
    }
    debugPrint('Navigating to search with query: $query');
    Navigator.pushNamed(context, '/search', arguments: {'query': query.trim()});
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      await SupabaseService.toggleFavorite(productId);

      setState(() {
        if (_favoriteProducts.contains(productId)) {
          _favoriteProducts.remove(productId);
        } else {
          _favoriteProducts.add(productId);
        }
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _showErrorSnackBar('Failed to update favorites');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      await SupabaseService.addToCart(product['id']);
      setState(() => _cartItemCount++);
      _showSuccessSnackBar('${product['name']} added to cart');
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      _showErrorSnackBar('Failed to add item to cart');
    }
  }

  void _navigateToCart() => Navigator.pushNamed(context, '/cart');
  void _navigateToProfile() => Navigator.pushNamed(context, '/profile');
  void _navigateToAllCategories() =>
      Navigator.pushNamed(context, '/categories');
  void _navigateToCategoryProducts(String categoryName) => Navigator.pushNamed(
    context,
    '/category-products',
    arguments: {'category': categoryName},
  );
  void _navigateToProductDetail(String productId) => Navigator.pushNamed(
    context,
    '/product-detail',
    arguments: {'productId': productId},
  );

  Future<void> _logoutUser() async {
    try {
      await SupabaseAuthService.signOut();
    } catch (e) {
      _showErrorSnackBar('Sign out failed: $e');
    }
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
