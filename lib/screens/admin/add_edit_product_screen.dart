// File: lib/screens/admin/add_edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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

  // Image handling variables
  File? _primaryImage;
  List<File> _additionalImages = [];
  String? _existingPrimaryImageUrl;
  List<String> _existingAdditionalImageUrls = [];
  final ImagePicker _picker = ImagePicker();

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

      // Initialize existing images
      _existingPrimaryImageUrl = product['image_url'];
      if (product['image_urls'] != null) {
        _existingAdditionalImageUrls = List<String>.from(product['image_urls']);
      }
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

  Future<void> _pickPrimaryImage() async {
    // Request storage permission
    final status = await Permission.photos.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission denied')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _primaryImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAdditionalImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _additionalImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePrimaryImage() {
    setState(() {
      _primaryImage = null;
      _existingPrimaryImageUrl = null;
    });
  }

  void _removeAdditionalImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingAdditionalImageUrls.removeAt(index);
      } else {
        _additionalImages.removeAt(index);
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await AdminService.checkUserRole();
    try {
      if (widget.product == null) {
        // Create new product with images
        await AdminService.createProductWithImages(
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
          primaryImage: _primaryImage,
          additionalImages: _additionalImages.isNotEmpty ? _additionalImages : null,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product created successfully')),
        );
      } else {
        // Update existing product with image management
        final updates = {
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
        };

        // Handle image updates manually if needed
        if (_existingAdditionalImageUrls.isNotEmpty || _additionalImages.isNotEmpty) {
          updates['image_urls'] = _existingAdditionalImageUrls;
        }

        await AdminService.updateProductWithImages(
          widget.product!['id'],
          updates,
          newPrimaryImage: _primaryImage,
          newAdditionalImages: _additionalImages.isNotEmpty ? _additionalImages : null,
          replacePrimaryImage: _primaryImage != null,
        );

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
              _buildImageSection(),
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

  Widget _buildImageSection() {
    return _buildSection(
      'Product Images',
      [
        // Primary Image Section
        Text(
          'Primary Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: _primaryImage != null || _existingPrimaryImageUrl != null
              ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _primaryImage != null
                    ? Image.file(
                  _primaryImage!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                )
                    : Image.network(
                  _existingPrimaryImageUrl!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey[300],
                      child: Icon(Icons.error, size: 40),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removePrimaryImage,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          )
              : InkWell(
            onTap: _pickPrimaryImage,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 8),
                Text(
                  'Add Primary Image',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_primaryImage == null && _existingPrimaryImageUrl == null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: ElevatedButton.icon(
              onPressed: _pickPrimaryImage,
              icon: Icon(Icons.camera_alt),
              label: Text('Choose Primary Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),

        SizedBox(height: 24),

        // Additional Images Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Additional Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickAdditionalImages,
              icon: Icon(Icons.add),
              label: Text('Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        // Display existing additional images
        if (_existingAdditionalImageUrls.isNotEmpty || _additionalImages.isNotEmpty)
          Container(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing images from server
                ..._existingAdditionalImageUrls.asMap().entries.map((entry) {
                  int index = entry.key;
                  String imageUrl = entry.value;
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeAdditionalImage(index, isExisting: true),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // New images from file picker
                ..._additionalImages.asMap().entries.map((entry) {
                  int index = entry.key;
                  File imageFile = entry.value;
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            imageFile,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeAdditionalImage(index, isExisting: false),
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          )
        else
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: InkWell(
              onTap: _pickAdditionalImages,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 30,
                    color: Colors.grey[600],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add Additional Images',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
            }),
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