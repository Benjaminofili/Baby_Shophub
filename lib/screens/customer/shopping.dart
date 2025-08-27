import 'package:flutter/material.dart';
import 'package:babyshop/theme.dart';
import '../../services/supabase_service.dart';
import '../../components/price_display.dart';
import 'checkout.dart'; // Import the checkout screen

class ShoppingCart extends StatefulWidget {
  const ShoppingCart({super.key});

  @override
  ShoppingCartState createState() => ShoppingCartState();
}

class ShoppingCartState extends State<ShoppingCart> {
  // Loading states
  bool _isLoading = true;
  final Map<String, bool> _itemUpdatingStates = {};

  // Cart items from Supabase
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() => _isLoading = true);

      final cartItems = await SupabaseService.getCartItems();

      if (mounted) {
        setState(() {
          _cartItems = cartItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cart items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load cart items');
      }
    }
  }

  Future<void> _updateQuantity(String cartItemId, int newQuantity) async {
    final itemIndex = _cartItems.indexWhere((item) => item['id'] == cartItemId);
    if (itemIndex == -1) return;

    if (_itemUpdatingStates[cartItemId] == true) return;

    final originalQuantity = _cartItems[itemIndex]['quantity'] as int;

    try {
      setState(() {
        _itemUpdatingStates[cartItemId] = true;
      });

      if (newQuantity <= 0) {
        setState(() {
          _cartItems.removeAt(itemIndex);
        });
        await SupabaseService.removeFromCart(cartItemId);
      } else {
        setState(() {
          _cartItems[itemIndex]['quantity'] = newQuantity;
        });
        await SupabaseService.updateCartItemQuantity(cartItemId, newQuantity);
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');

      if (newQuantity <= 0) {
        setState(() {
          _cartItems.insert(itemIndex, {
            'id': cartItemId,
            'quantity': originalQuantity,
          });
        });
      } else {
        setState(() {
          if (itemIndex < _cartItems.length) {
            _cartItems[itemIndex]['quantity'] = originalQuantity;
          }
        });
      }

      _showErrorSnackBar('Failed to update item quantity');
    } finally {
      if (mounted) {
        setState(() {
          _itemUpdatingStates.remove(cartItemId);
        });
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    final itemIndex = _cartItems.indexWhere((item) => item['id'] == cartItemId);
    if (itemIndex == -1 || _itemUpdatingStates[cartItemId] == true) return;

    try {
      setState(() {
        _itemUpdatingStates[cartItemId] = true;
      });

      setState(() {
        _cartItems.removeAt(itemIndex);
      });
      await SupabaseService.removeFromCart(cartItemId);
    } catch (e) {
      debugPrint('Error removing item: $e');
      setState(() {
        _cartItems.insert(itemIndex, {
          'id': cartItemId,
          'quantity': _cartItems[itemIndex]['quantity'],
          'product': _cartItems[itemIndex]['product'],
        });
      });
      _showErrorSnackBar('Failed to remove item');
    } finally {
      if (mounted) {
        setState(() {
          _itemUpdatingStates.remove(cartItemId);
        });
      }
    }
  }

  Future<void> _clearCart() async {
    if (_cartItems.isEmpty) return;

    try {
      setState(() => _isLoading = true);
      await SupabaseService.clearCart();
      if (mounted) {
        setState(() {
          _cartItems.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to clear cart');
      }
    }
  }

  void _handleQuantityChange(String cartItemId, int change) {
    final itemIndex = _cartItems.indexWhere((item) => item['id'] == cartItemId);
    if (itemIndex == -1) return;

    final currentQuantity = _cartItems[itemIndex]['quantity'] as int;
    final newQuantity = currentQuantity + change;

    if (newQuantity >= 0) {
      _updateQuantity(cartItemId, newQuantity);
    }
  }

  double _calculateTotal() {
    return _cartItems.fold<double>(0.0, (total, item) {
      final price = (item['product']['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = item['quantity'] as int? ?? 0;
      return total + (price * quantity);
    });
  }

  // Navigate to checkout with cart data
  void _navigateToCheckout() {
    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Your cart is empty');
      return;
    }

    final total = _calculateTotal();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: _cartItems,
          totalAmount: total,
        ),
      ),
    ).then((result) {
      // Refresh cart when returning from checkout
      if (result == true) {
        // Order was successful, clear cart
        setState(() {
          _cartItems.clear();
        });
      } else {
        // Just refresh cart in case of changes
        _loadCartItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea( // Added SafeArea to ensure content is below status bar
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10), // Adjusted padding for better accessibility
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  ),
                  Text(
                    "Shopping bag",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _cartItems.isEmpty ? null : _clearCart,
                    icon: Icon(Icons.delete, color: _cartItems.isEmpty ? Colors.grey : AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cart content
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
                    : _cartItems.isEmpty
                    ? _buildEmptyCart()
                    : _buildCartContent(),
              ),

              // Bottom section with total and checkout
              if (_cartItems.isNotEmpty) _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to get started!',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
                  (route) => false,
              arguments: 0,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return ListView.builder(
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final product = item['product'] as Map<String, dynamic>;
        final cartItemId = item['id'] as String;
        final quantity = item['quantity'] as int;
        final price = (product['price'] as num).toDouble();
        final name = product['name'] as String;
        final category = product['category'] as String? ?? 'Unknown';
        final imageUrl = product['image_url'] as String? ?? '';
        final isUpdating = _itemUpdatingStates[cartItemId] ?? false;

        return _buildCartItem(
          cartItemId: cartItemId,
          name: name,
          category: category,
          price: price,
          quantity: quantity,
          imageUrl: imageUrl,
          isUpdating: isUpdating,
        );
      },
    );
  }

  Widget _buildBottomSection() {
    final total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              PriceDisplay(
                price: total,
                priceStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                currency: '₦',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cartItems.isEmpty ? null : _navigateToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Proceed to Checkout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem({
    required String cartItemId,
    required String name,
    required String category,
    required double price,
    required int quantity,
    required String imageUrl,
    required bool isUpdating,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
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
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Product Name and Category
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Category: $category",
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Quantity, Remove, and Price Row
                        Row(
                          children: [
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: isUpdating
                                        ? null
                                        : () {
                                      _handleQuantityChange(cartItemId, -1);
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: isUpdating
                                            ? Colors.grey
                                            : AppTheme.primaryDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Text(
                                        quantity.toString(),
                                        key: ValueKey(quantity),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: isUpdating
                                        ? null
                                        : () {
                                      _handleQuantityChange(cartItemId, 1);
                                    },
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: isUpdating
                                            ? Colors.grey
                                            : AppTheme.primaryDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Remove Button
                            IconButton(
                              icon: Icon(Icons.delete, color: AppTheme.textPrimary),
                              onPressed: isUpdating
                                  ? null
                                  : () => _removeItem(cartItemId),
                            ),

                            const Spacer(),

                            // Price
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: PriceDisplay(
                                key: ValueKey(
                                  '${cartItemId}_${quantity}_$price',
                                ),
                                price: price * quantity,
                                priceStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                currency: '₦',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay for individual item
          if (isUpdating)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
}