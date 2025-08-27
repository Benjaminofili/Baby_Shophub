// File: lib/screens/favorites_page_content.dart
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../components/product_card.dart';
import '../../components/loading_widget.dart';
import '../../components/empty_state_widget.dart';
import '../../services/supabase_service.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favoriteProducts = [];
  Set<String> _favoriteIds = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final favoriteProducts = await SupabaseService.getFavoriteProducts();
      final favoriteIds = await SupabaseService.getUserFavorites();

      if (mounted) {
        setState(() {
          _favoriteProducts = favoriteProducts
              .map(
                (product) => SupabaseService.formatProductForDisplay(product),
              )
              .toList();
          _favoriteIds = favoriteIds;
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

  Future<void> _handleRefresh() async {
    await _loadFavorites();
  }

  Future<void> _toggleFavorite(String productId) async {
    try {
      await SupabaseService.toggleFavorite(productId);

      setState(() {
        if (_favoriteIds.contains(productId)) {
          _favoriteIds.remove(productId);
          _favoriteProducts.removeWhere(
            (product) => product['id'] == productId,
          );
        } else {
          _favoriteIds.add(productId);
        }
      });

      _showSuccessSnackBar('Favorites updated');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      await SupabaseService.addToCart(product['id']);
      _showSuccessSnackBar('${product['name']} added to cart');
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _navigateToProductDetail(String productId) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {'productId': productId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button for bottom nav
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading your favorites...');
    }

    if (_error.isNotEmpty) {
      return EmptyStateWidget(
        message: 'Failed to load favorites',
        subtitle: _error,
        icon: Icons.error_outline,
        actionText: 'Retry',
        onActionPressed: _loadFavorites,
      );
    }

    if (_favoriteProducts.isEmpty) {
      return const EmptyStateWidget(
        message: 'No favorites yet',
        subtitle: 'Start adding products to your favorites to see them here',
        icon: Icons.favorite_outline,
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${_favoriteProducts.length} ${_favoriteProducts.length == 1 ? 'item' : 'items'} in favorites',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = _favoriteProducts[index];
              return DynamicProductCard(
                product: product,
                isFavorite: _favoriteProducts.contains(product['id']),
                onFavoriteTap: () => _toggleFavorite(product['id']),
                onAddToCart: () => _addToCart(product),
                onTap: () => _navigateToProductDetail(product['id']),
                showDescription: true,
                showAddToCart: true,
              );
            }, childCount: _favoriteProducts.length),
          ),
        ),
      ],
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
