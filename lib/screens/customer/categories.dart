// File: lib/screens/categories_page_content.dart
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../components/category_card.dart';
import '../../components/loading_widget.dart';
import '../../components/empty_state_widget.dart';
import '../../services/supabase_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

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
                  'description': category['description'] ?? '',
                },
              )
              .toList();
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
    await _loadCategories();
  }

  void _navigateToCategoryProducts(String categoryName) {
    Navigator.pushNamed(
      context,
      '/category-products',
      arguments: {'category': categoryName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Categories',
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
      return const LoadingWidget(message: 'Loading categories...');
    }

    if (_error.isNotEmpty) {
      return EmptyStateWidget(
        message: 'Failed to load categories',
        subtitle: _error,
        icon: Icons.error_outline,
        actionText: 'Retry',
        onActionPressed: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return const EmptyStateWidget(
        message: 'No categories available',
        subtitle: 'Categories will appear here when they become available',
        icon: Icons.category_outlined,
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final category = _categories[index];
              return CategoryCard(
                category: category,
                onTap: () => _navigateToCategoryProducts(category['name']),
                size: null,
              );
            }, childCount: _categories.length),
          ),
        ),
      ],
    );
  }
}
