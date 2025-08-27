// lib/utils/profile_dialogs.dart
import 'package:flutter/material.dart';
import '../theme.dart';

class ProfileDialogs {
  // Payment Methods Dialog
  static void showPaymentMethods(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Payment Methods'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available payment options for your orders:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 16),

            // Cash on Delivery
            ListTile(
              leading: Icon(Icons.money, color: Colors.green),
              title: Text('Cash on Delivery'),
              subtitle: Text('Pay when your order arrives at your doorstep'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
              contentPadding: EdgeInsets.zero,
            ),

            // Bank Transfer
            ListTile(
              leading: Icon(Icons.account_balance, color: AppTheme.primary),
              title: Text('Bank Transfer'),
              subtitle: Text('Direct payment to our bank account'),
              trailing: TextButton(
                onPressed: () => showBankDetails(context),
                child: Text('View Details'),
              ),
              contentPadding: EdgeInsets.zero,
            ),

            // Card Payment (Future)
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.grey),
              title: Text('Credit/Debit Card'),
              subtitle: Text('Online card payment (Coming Soon)'),
              trailing: Icon(Icons.lock, color: Colors.grey),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Bank Details Dialog
  static void showBankDetails(BuildContext context) {
    Navigator.pop(context); // Close payment methods dialog first

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bank Transfer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBankDetail('Bank Name', 'First Bank Nigeria'),
            _buildBankDetail('Account Name', 'BabyShopHub Ltd'),
            _buildBankDetail('Account Number', '2034567890'),
            _buildBankDetail('Sort Code', '011-151-001'),
            _buildBankDetail('Reference', 'Your Order ID'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please include your order ID as payment reference for faster processing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar(context, 'Bank details copied to clipboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Copy Details'),
          ),
        ],
      ),
    );
  }

  // Shipping Addresses Dialog
  static void showShippingAddresses(
      BuildContext context,
      Map<String, dynamic>? userProfile,
      Function(String) onAddressUpdate,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Shipping Addresses'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current/Default Address
              if (userProfile?['address'] != null && userProfile!['address'].toString().isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.home, color: AppTheme.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Default Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'PRIMARY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              userProfile!['address'],
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Add New Address Option
              InkWell(
                onTap: () => showAddAddress(context, onAddressUpdate),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_location, color: AppTheme.secondary),
                      SizedBox(width: 12),
                      Text(
                        'Add New Address',
                        style: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),
              Text(
                'Multiple shipping addresses feature coming soon!',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // Add Address Dialog
  static void showAddAddress(BuildContext context, Function(String) onAddressUpdate) {
    Navigator.pop(context); // Close shipping addresses dialog

    final newAddressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newAddressController,
              decoration: InputDecoration(
                labelText: 'Complete Address',
                hintText: 'Enter your full address with landmarks...',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            Text(
              'This will update your profile address',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newAddress = newAddressController.text.trim();
              if (newAddress.isNotEmpty) {
                Navigator.pop(context);
                onAddressUpdate(newAddress);
                _showSuccessSnackBar(context, 'Address updated successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Add Address'),
          ),
        ],
      ),
    );
  }

  // Order Tracking Dialog
  static void showOrderTracking(BuildContext context) {
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Track Your Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your tracking number to track your order:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: InputDecoration(
                labelText: 'Tracking Number',
                hintText: 'e.g., TRK1234',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final trackingNumber = trackingController.text.trim();
              if (trackingNumber.isNotEmpty) {
                Navigator.pop(context);
                _showSuccessSnackBar(context, 'Tracking: $trackingNumber');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Track'),
          ),
        ],
      ),
    );
  }

  // Coming Soon Dialog
  static void showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('This feature is coming soon! Stay tuned for updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to build bank details
  static Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show success snackbar
  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}