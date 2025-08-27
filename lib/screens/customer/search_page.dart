import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme.dart';
import '../../components/product_card.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // State management
  bool _isSearching = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  Set<String> _favoriteProducts = {};
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _currentQuery = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _loadRecentSearches();
    _loadFavorites();
  }

  Future<void> _loadRecentSearches() async {
    // In a real app, you might store this in SharedPreferences or user preferences
    // For now, we'll keep it simple with in-memory storage
    setState(() {
      _recentSearches = [
        'baby bottles',
        'diapers',
        'baby clothes',
        'toys',
        'strollers',
      ];
    });
  }

  Future<void> _loadFavorites() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('favorites')
            .select('product_id')
            .eq('user_id', user.id);
        if (mounted) {
          setState(() {
            _favoriteProducts = response
                .map<String>((fav) => fav['product_id'].toString())
                .toSet();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _currentQuery = query.trim();
    });

    try {
      // Search in products table with multiple criteria
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .eq('is_active', true)
          .or(
            'name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%',
          );

      if (mounted) {
        setState(() {
          _searchResults = response
              .map<Map<String, dynamic>>(
                (product) => _formatProductForDisplay(product),
              )
              .toList();
          _isSearching = false;
        });

        // Add to recent searches if not already present
        if (!_recentSearches.contains(query.toLowerCase())) {
          setState(() {
            _recentSearches.insert(0, query.toLowerCase());
            if (_recentSearches.length > 10) {
              _recentSearches = _recentSearches.take(10).toList();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error performing search: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        _showErrorSnackBar('Search failed. Please try again.');
      }
    }
  }

  Map<String, dynamic> _formatProductForDisplay(Map<String, dynamic> product) {
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
      'is_new': false,
      'category': product['category'] ?? 'Unknown',
      'description': product['description'],
      'stock_quantity': product['stock_quantity'] ?? 0,
    };
  }

  void _onSearchSubmitted(String query) {
    _performSearch(query);
    _searchFocusNode.unfocus();
  }

  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _currentQuery = '';
    });
  }

  Future<void> _toggleFavorite(String productId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Please login to add favorites');
      return;
    }

    try {
      if (_favoriteProducts.contains(productId)) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
        setState(() => _favoriteProducts.remove(productId));
      } else {
        await Supabase.instance.client.from('favorites').insert({
          'user_id': user.id,
          'product_id': productId,
        });
        setState(() => _favoriteProducts.add(productId));
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _showErrorSnackBar('Failed to update favorites');
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorSnackBar('Please login to add items to cart');
      return;
    }

    try {
      final productId = product['id'].toString();
      final existingItem = await Supabase.instance.client
          .from('cart')
          .select('quantity')
          .eq('user_id', user.id)
          .eq('product_id', productId)
          .maybeSingle();

      if (existingItem != null) {
        final newQuantity = (existingItem['quantity'] as int) + 1;
        await Supabase.instance.client
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('user_id', user.id)
            .eq('product_id', productId);
      } else {
        await Supabase.instance.client.from('cart').insert({
          'user_id': user.id,
          'product_id': productId,
          'quantity': 1,
        });
      }

      _showSuccessSnackBar('${product['name']} added to cart');
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      _showErrorSnackBar('Failed to add item to cart');
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
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: widget.initialQuery == null,
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearchSubmitted,
            decoration: InputDecoration(
              hintText: 'Search for baby products...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.primary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Search suggestions/filters could go here
          if (!_hasSearched && _recentSearches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((search) {
                      return GestureDetector(
                        onTap: () => _onRecentSearchTap(search),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                search,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          // Search results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Searching...'),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Search for baby products',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Find diapers, toys, clothes, and more',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for different keywords',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_searchResults.length} results for "$_currentQuery"',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return DynamicProductCard(
                product: product,
                isFavorite: _favoriteProducts.contains(product['id']),
                onFavoriteTap: () => _toggleFavorite(product['id']),
                onAddToCart: () => _addToCart(product),
                onTap: () => _navigateToProductDetail(product['id']),
                showDescription: true,
                showAddToCart: true,
              );
            },
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
