// File: lib/screens/category_products_page.dart
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../components/product_card.dart'; // Make sure this import is correct
import '../../components/loading_widget.dart';
import '../../components/empty_state_widget.dart';
import '../../services/supabase_service.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;

  const CategoryProductsPage({super.key, required this.categoryName});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  Set<String> _favoriteProducts = {};
  String _error = '';
  String _selectedFilter = 'All';
  List<String> _subCategories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadProducts(), _loadFavorites()]);
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final products = await SupabaseService.getProducts(
        category: widget.categoryName,
      );

      if (mounted) {
        final formattedProducts = products
            .map((product) => SupabaseService.formatProductForDisplay(product))
            .toList();

        // Extract unique subcategories based on product names or descriptions
        final subcategories = <String>{'All'};
        if (widget.categoryName == 'Tableware') {
          subcategories.addAll([
            'Plates',
            'Cutlery',
            'Travel cups',
            'Snack cups',
            'Bowls',
          ]);
        }

        setState(() {
          _products = formattedProducts;
          _subCategories = subcategories.toList();
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

  Future<void> _loadFavorites() async {
    try {
      final favorites = await SupabaseService.getUserFavorites();
      if (mounted) {
        setState(() {
          _favoriteProducts = favorites;
        });
      }
    } catch (e) {
      // Silently handle favorites loading error
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
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

  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search');
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedFilter == 'All') {
      return _products;
    }

    // Filter products based on the selected subcategory
    return _products.where((product) {
      final name = (product['name'] as String).toLowerCase();
      final description = (product['description'] as String? ?? '')
          .toLowerCase();
      final filter = _selectedFilter.toLowerCase();

      return name.contains(filter) || description.contains(filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
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
      return const LoadingWidget(message: 'Loading products...');
    }

    if (_error.isNotEmpty) {
      return EmptyStateWidget(
        message: 'Failed to load products',
        subtitle: _error,
        icon: Icons.error_outline,
        actionText: 'Retry',
        onActionPressed: _loadProducts,
      );
    }

    if (_products.isEmpty) {
      return EmptyStateWidget(
        message: 'No products found',
        subtitle: 'No products available in ${widget.categoryName} category',
        icon: Icons.inventory_2_outlined,
        actionText: 'Browse Other Categories',
        onActionPressed: () =>
            Navigator.pushReplacementNamed(context, '/categories'),
      );
    }

    final filteredProducts = _filteredProducts;

    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search in ${widget.categoryName}...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onTap: _navigateToSearch,
            readOnly: true,
          ),
        ),

        // Filter tabs
        if (_subCategories.length > 1) _buildFilterTabs(),

        // Products grid
        Expanded(
          child: filteredProducts.isEmpty
              ? EmptyStateWidget(
            message: 'No products found',
            subtitle: 'No products match the selected filter',
            icon: Icons.filter_list_off,
            actionText: 'Clear Filter',
            onActionPressed: () {
              setState(() {
                _selectedFilter = 'All';
              });
            },
          )
              : CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${filteredProducts.length} products found',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = filteredProducts[index];
                    return DynamicProductCard( // Changed from ProductCard to DynamicProductCard
                      product: product,
                      isFavorite: _favoriteProducts.contains(
                        product['id'],
                      ),
                      onFavoriteTap: () =>
                          _toggleFavorite(product['id']),
                      onAddToCart: () => _addToCart(product),
                      onTap: () =>
                          _navigateToProductDetail(product['id']),
                    );
                  }, childCount: filteredProducts.length),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subCategories.length,
        itemBuilder: (context, index) {
          final category = _subCategories[index];
          final isSelected = _selectedFilter == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = category;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              ),
            ),
          );
        },
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