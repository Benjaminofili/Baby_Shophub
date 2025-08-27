// File: lib/screens/admin/admin_categories_screen.dart
import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../components/loading_widget.dart';
import '../../../components/error_widget.dart';
import '../../../components/empty_state_widget.dart';
import '../../../components/custom_app_bar.dart';
import '../../../components/Validatetextfield.dart';
import '../../../components/button.dart';
import '../../../theme.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categories = await AdminService.getAllCategories();

      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showCategoryDialog({Map<String, dynamic>? category}) async {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descController = TextEditingController(text: category?['description'] ?? '');
    final sortOrderController = TextEditingController(
      text: category?['sort_order']?.toString() ?? '0',
    );
    bool isActive = category?['is_active'] ?? true;
    String selectedIcon = category?['icon_name'] ?? 'category';

    final icons = [
      'category', 'baby', 'toys', 'clothing', 'food', 'care', 'safety', 'furniture'
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValidatedTextField(
                  hintText: 'Category Name',
                  controller: nameController,
                ),
                SizedBox(height: 16),
                ValidatedTextField(
                  hintText: 'Description (Optional)',
                  controller: descController,
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedIcon,
                  decoration: InputDecoration(
                    labelText: 'Icon',
                    border: OutlineInputBorder(),
                  ),
                  items: icons.map((icon) {
                    return DropdownMenuItem(
                      value: icon,
                      child: Row(
                        children: [
                          Icon(_getIconData(icon), size: 20),
                          SizedBox(width: 8),
                          Text(icon.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedIcon = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                ValidatedTextField(
                  hintText: 'Sort Order',
                  controller: sortOrderController,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Active'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                  activeColor: AppTheme.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category name is required')),
                  );
                  return;
                }

                try {
                  if (category == null) {
                    await AdminService.createCategory(
                      name: name,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                      iconName: selectedIcon,
                      sortOrder: int.tryParse(sortOrderController.text) ?? 0,
                      isActive: isActive,
                    );
                  } else {
                    await AdminService.updateCategory(category['id'], {
                      'name': name,
                      'description': descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                      'icon_name': selectedIcon,
                      'sort_order': int.tryParse(sortOrderController.text) ?? 0,
                      'is_active': isActive,
                    });
                  }

                  if (!mounted) return;
                  Navigator.pop(dialogContext); // Use dialogContext
                  _loadCategories();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(category == null
                          ? 'Category created successfully'
                          : 'Category updated successfully'),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(category == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );

    // Dispose controllers after dialog is closed
    nameController.dispose();
    descController.dispose();
    sortOrderController.dispose();
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${category['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.deleteCategory(category['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category deleted successfully')),
        );
        _loadCategories();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'baby': return Icons.child_care;
      case 'toys': return Icons.toys;
      case 'clothing': return Icons.checkroom;
      case 'food': return Icons.restaurant;
      case 'care': return Icons.healing;
      case 'safety': return Icons.security;
      case 'furniture': return Icons.bed;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Categories Management',
        subtitle: _categories.isNotEmpty ? '${_categories.length} categories' : null,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingWidget(message: 'Loading categories...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error!,
        actionText: 'Retry',
        onActionPressed: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return EmptyStateWidget(
        message: 'No categories found',
        subtitle: 'Add your first category to organize products',
        icon: Icons.category,
        actionText: 'Add Category',
        onActionPressed: () => _showCategoryDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ReorderableListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _categories.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _categories.removeAt(oldIndex);
            _categories.insert(newIndex, item);
          });

          // Update sort order in database
          _updateSortOrder();
        },
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category, index);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    final isActive = category['is_active'] ?? true;

    return Card(
      key: ValueKey(category['id']),
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Drag handle
            Icon(Icons.drag_handle, color: Colors.grey),
            SizedBox(width: 16),

            // Category icon
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(category['icon_name'] ?? 'category'),
                color: isActive ? AppTheme.primary : Colors.grey,
                size: 24,
              ),
            ),
            SizedBox(width: 16),

            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category['name'] ?? 'Unnamed Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppTheme.textPrimary : Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (category['description'] != null && category['description'].toString().isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      category['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Sort: ${category['sort_order'] ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'ID: ${category['id'].toString().substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showCategoryDialog(category: category);
                    break;
                  case 'toggle_status':
                    AdminService.updateCategory(category['id'], {
                      'is_active': !isActive,
                    }).then((_) {
                      _loadCategories();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isActive
                              ? 'Category deactivated'
                              : 'Category activated'),
                        ),
                      );
                    });
                    break;
                  case 'delete':
                    _deleteCategory(category);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSortOrder() async {
    try {
      for (int i = 0; i < _categories.length; i++) {
        await AdminService.updateCategory(_categories[i]['id'], {
          'sort_order': i,
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating sort order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}