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

class _FavoritesPageState extends State<FavoritesPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  List<Map<String, dynamic>> _favoriteProducts = [];
  Set<String> _favoriteIds = {};
  String _error = '';

  @override
  bool get wantKeepAlive => false; // Always get fresh data

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFavorites();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes back to foreground
      _loadFavorites();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload when this page becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFavorites();
      }
    });
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 FavoritesPage: Loading favorites...');
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Load both favorites list and IDs in parallel
      final results = await Future.wait([
        SupabaseService.getFavoriteProducts(),
        SupabaseService.getUserFavorites(),
      ]);

      final favoriteProducts = results[0] as List<Map<String, dynamic>>;
      final favoriteIds = results[1] as Set<String>;

      debugPrint('📊 FavoritesPage: Loaded ${favoriteProducts.length} products, ${favoriteIds.length} IDs');

      if (mounted) {
        setState(() {
          _favoriteProducts = favoriteProducts
              .map((product) => SupabaseService.formatProductForDisplay(product))
              .toList();
          _favoriteIds = favoriteIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ FavoritesPage: Error loading favorites: $e');
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
    if (!mounted) return;

    try {
      debugPrint('🔄 FavoritesPage: Toggling favorite for $productId');

      // Optimistic update for better UX
      final wasLiked = _favoriteIds.contains(productId);
      setState(() {
        if (wasLiked) {
          _favoriteIds.remove(productId);
          _favoriteProducts.removeWhere((product) => product['id'] == productId);
        }
        // Note: We don't add products optimistically since we'd need the full product data
      });

      await SupabaseService.toggleFavorite(productId);

      // Force reload to ensure data consistency
      await _loadFavorites();

      if (mounted) {
        _showSuccessSnackBar(
            wasLiked ? 'Removed from favorites' : 'Added to favorites'
        );
      }
    } catch (e) {
      debugPrint('❌ FavoritesPage: Error toggling favorite: $e');
      // Revert optimistic update on error
      await _loadFavorites();
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      await SupabaseService.addToCart(product['id']);
      if (mounted) {
        _showSuccessSnackBar('${product['name']} added to cart');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _navigateToProductDetail(String productId) {
    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: {'productId': productId},
    ).then((_) {
      // Refresh favorites when returning from product detail
      _loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Refresh favorites',
          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_favoriteProducts.length} ${_favoriteProducts.length == 1 ? 'item' : 'items'} in favorites',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                // Debug info (remove in production)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Debug: ${_favoriteIds.length} favorite IDs\n${_favoriteIds.join(', ')}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
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
                isFavorite: _favoriteIds.contains(product['id']),
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