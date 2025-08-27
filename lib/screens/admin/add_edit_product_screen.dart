// File: lib/screens/admin/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../components/loading_widget.dart';
import '../../../components/custom_app_bar.dart';
import '../../../components/Validatetextfield.dart';
import '../../../components/button.dart';
import '../../../theme.dart';

class AddEditProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _ageRangeController = TextEditingController();
  final _materialController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();

  String _selectedCategory = 'feeding';
  String? _selectedSubcategory;
  bool _isActive = true;
  bool _featured = false;
  bool _safetyCertified = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'feeding',
    'clothing',
    'toys',
    'care',
    'furniture',
    'safety',
  ];

  final Map<String, List<String>> _subcategories = {
    'feeding': ['bottles', 'formula', 'baby_food', 'bibs', 'high_chairs'],
    'clothing': ['bodysuits', 'sleepwear', 'outerwear', 'shoes', 'accessories'],
    'toys': ['soft_toys', 'educational', 'rattles', 'books', 'musical'],
    'care': ['diapers', 'bath', 'skincare', 'health', 'grooming'],
    'furniture': ['cribs', 'changing_tables', 'storage', 'decorations'],
    'safety': ['gates', 'locks', 'monitors', 'car_seats', 'helmets'],
  };

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = product['price']?.toString() ?? '';
      _stockController.text = product['stock_quantity']?.toString() ?? '0';
      _brandController.text = product['brand'] ?? '';
      _ageRangeController.text = product['age_range'] ?? '';
      _materialController.text = product['material'] ?? '';
      _weightController.text = product['weight_kg']?.toString() ?? '';
      _dimensionsController.text = product['dimensions_cm'] ?? '';
      _selectedCategory = product['category'] ?? 'feeding';
      _selectedSubcategory = product['subcategory'];
      _isActive = product['is_active'] ?? true;
      _featured = product['featured'] ?? false;
      _safetyCertified = product['safety_certified'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _ageRangeController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await AdminService.checkUserRole();
    try {
      if (widget.product == null) {
        // Create new product
        await AdminService.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory,
          subcategory: _selectedSubcategory,
          brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
          ageRange: _ageRangeController.text.trim().isNotEmpty ? _ageRangeController.text.trim() : null,
          material: _materialController.text.trim().isNotEmpty ? _materialController.text.trim() : null,
          weightKg: _weightController.text.trim().isNotEmpty ? double.tryParse(_weightController.text) : null,
          dimensionsCm: _dimensionsController.text.trim().isNotEmpty ? _dimensionsController.text.trim() : null,
          stockQuantity: int.parse(_stockController.text),
          isActive: _isActive,
          featured: _featured,
          safetyCertified: _safetyCertified,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product created successfully')),
        );
      } else {
        // Update existing product
        await AdminService.updateProduct(widget.product!['id'], {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text),
          'category': _selectedCategory,
          'subcategory': _selectedSubcategory,
          'brand': _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
          'age_range': _ageRangeController.text.trim().isNotEmpty ? _ageRangeController.text.trim() : null,
          'material': _materialController.text.trim().isNotEmpty ? _materialController.text.trim() : null,
          'weight_kg': _weightController.text.trim().isNotEmpty ? double.tryParse(_weightController.text) : null,
          'dimensions_cm': _dimensionsController.text.trim().isNotEmpty ? _dimensionsController.text.trim() : null,
          'stock_quantity': int.parse(_stockController.text),
          'is_active': _isActive,
          'featured': _featured,
          'safety_certified': _safetyCertified,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product updated successfully')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: widget.product == null ? 'Add Product' : 'Edit Product',
      ),
      body: _isLoading
          ? LoadingWidget(message: 'Saving product...')
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              SizedBox(height: 24),
              _buildCategorySection(),
              SizedBox(height: 24),
              _buildDetailsSection(),
              SizedBox(height: 24),
              _buildInventorySection(),
              SizedBox(height: 24),
              _buildOptionsSection(),
              SizedBox(height: 32),
              CustomButton(
                text: widget.product == null ? 'Create Product' : 'Update Product',
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      'Basic Information',
      [
        ValidatedTextField(
          hintText: 'Product Name *',
          controller: _nameController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Product name is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        ValidatedTextField(
          hintText: 'Description *',
          controller: _descriptionController,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Description is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        ValidatedTextField(
          hintText: 'Price (₦) *',
          controller: _priceController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Price is required';
            }
            if (double.tryParse(value) == null || double.parse(value) <= 0) {
              return 'Enter a valid price';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return _buildSection(
      'Category',
      [
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category *',
            border: UnderlineInputBorder(),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category.replaceAll('_', ' ').toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
              _selectedSubcategory = null;
            });
          },
          validator: (value) => value == null ? 'Category is required' : null,
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          value: _selectedSubcategory,
          decoration: InputDecoration(
            labelText: 'Subcategory',
            border: UnderlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Select Subcategory'),
            ),
            ...(_subcategories[_selectedCategory] ?? []).map((subcategory) {
              return DropdownMenuItem<String?>(
                value: subcategory,
                child: Text(subcategory.replaceAll('_', ' ').toUpperCase()),
              );
            }), // Map subcategories to DropdownMenuItem
          ],
          onChanged: (value) {
            setState(() {
              _selectedSubcategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return _buildSection(
      'Product Details',
      [
        ValidatedTextField(
          hintText: 'Brand',
          controller: _brandController,
        ),
        SizedBox(height: 16),
        ValidatedTextField(
          hintText: 'Age Range (e.g., 0-6 months)',
          controller: _ageRangeController,
        ),
        SizedBox(height: 16),
        ValidatedTextField(
          hintText: 'Material',
          controller: _materialController,
        ),
        SizedBox(height: 16),
        ValidatedTextField(
          hintText: 'Weight (kg)',
          controller: _weightController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16),
        ValidatedTextField(
          hintText: 'Dimensions (cm)',
          controller: _dimensionsController,
        ),
      ],
    );
  }

  Widget _buildInventorySection() {
    return _buildSection(
      'Inventory',
      [
        ValidatedTextField(
          hintText: 'Stock Quantity *',
          controller: _stockController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Stock quantity is required';
            }
            if (int.tryParse(value) == null || int.parse(value) < 0) {
              return 'Enter a valid stock quantity';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return _buildSection(
      'Options',
      [
        SwitchListTile(
          title: Text('Active'),
          subtitle: Text('Product is available for purchase'),
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
          activeColor: AppTheme.primary,
        ),
        SwitchListTile(
          title: Text('Featured'),
          subtitle: Text('Show in featured products'),
          value: _featured,
          onChanged: (value) {
            setState(() {
              _featured = value;
            });
          },
          activeColor: AppTheme.primary,
        ),
        SwitchListTile(
          title: Text('Safety Certified'),
          subtitle: Text('Product has safety certification'),
          value: _safetyCertified,
          onChanged: (value) {
            setState(() {
              _safetyCertified = value;
            });
          },
          activeColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}