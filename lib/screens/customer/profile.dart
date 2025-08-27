// lib/screens/profile.dart - Clean Profile Page
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/supabase_service.dart';
import '../../routes/app_routes.dart';
import '../../utils/profile_dialogs.dart';
import '../admin/admin_access_widget.dart';
import 'order_history.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isUpdating = false;
  Map<String, dynamic>? _userProfile;
  int _cartItemCount = 0;
  int _favoriteItemCount = 0;
  int _orderCount = 0;
  bool _isAdmin = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Load user profile
      final profile = await SupabaseAuthService.getUserProfile();
      final isAdmin = await SupabaseAuthService.isCurrentUserAdmin();

      // Load user statistics
      final cartCount = await SupabaseService.getCartItemCount();
      final favorites = await SupabaseService.getUserFavorites();
      final orderCount = await SupabaseService.getUserOrderCount();

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isAdmin = isAdmin;
          _cartItemCount = cartCount;
          _favoriteItemCount = favorites.length;
          _orderCount = orderCount;
          _isLoading = false;
        });

        // Populate form controllers
        if (profile != null) {
          _nameController.text = profile['full_name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _addressController.text = profile['address'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load profile data');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_isUpdating) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showErrorSnackBar('Name is required');
      return;
    }

    try {
      setState(() => _isUpdating = true);

      final result = await SupabaseAuthService.updateUserProfile(
        name: name,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccessSnackBar(result['message']);
        await _loadUserData(); // Reload to get updated data
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await SupabaseAuthService.signOut();
        // Navigation will be handled by AuthWrapper
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Sign out failed. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsCards(),
              SizedBox(height: 20),
              if (_isAdmin) ...[
                _buildAdminAccessCard(),
                SizedBox(height: 20),
              ],
              _buildProfileForm(),
              SizedBox(height: 20),
              _buildMenuItems(),
              SizedBox(height: 40),
              _buildSignOutButton(),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = SupabaseAuthService.currentUser;
    final profileData = _userProfile;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: profileData?['avatar_url'] != null
                ? ClipOval(
              child: Image.network(
                profileData!['avatar_url'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              ),
            )
                : _buildDefaultAvatar(),
          ),
          SizedBox(height: 16),

          // User Name with admin badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profileData?['full_name'] ?? 'BabyShop Customer',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_isAdmin) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4),

          // User Email
          Text(
            user?.email ?? 'No email',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final userName = _userProfile?['full_name'] ?? 'User';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAdminAccessCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Manage products, orders, and users',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => AppRoutes.navigateToAdmin(context),
                  icon: Icon(Icons.dashboard, size: 18),
                  label: Text('Admin Panel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade600,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => AdminQuickActions.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Icon(Icons.more_vert, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.shopping_cart,
              label: 'Cart Items',
              value: _cartItemCount.toString(),
              color: AppTheme.primary,
              onTap: () => _navigateToTab(3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              label: 'Favorites',
              value: _favoriteItemCount.toString(),
              color: Colors.red,
              onTap: () => _navigateToTab(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.receipt_long,
              label: 'Orders',
              value: _orderCount.toString(),
              color: AppTheme.secondary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 20),

          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person, color: AppTheme.primary),
            ),
          ),
          SizedBox(height: 16),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),

          // Address Field
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on, color: AppTheme.primary),
            ),
          ),
          SizedBox(height: 24),

          // Update Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUpdating ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isUpdating
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                'Update Profile',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Admin menu item if user is admin
          if (_isAdmin) ...[
            _buildMenuItem(
              icon: Icons.admin_panel_settings,
              title: 'Administrator Panel',
              onTap: () => AppRoutes.navigateToAdmin(context),
              iconColor: Colors.orange,
            ),
            Divider(height: 1),
          ],

          // Order History
          _buildMenuItem(
            icon: Icons.shopping_bag,
            title: 'Order History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          Divider(height: 1),

          // Order Tracking
          _buildMenuItem(
            icon: Icons.local_shipping,
            title: 'Track Order',
            onTap: () => ProfileDialogs.showOrderTracking(context),
          ),
          Divider(height: 1),

          // Payment Methods (SRS Required)
          _buildMenuItem(
            icon: Icons.payment,
            title: 'Payment Methods',
            onTap: () => ProfileDialogs.showPaymentMethods(context),
          ),
          Divider(height: 1),

          // Shipping Addresses (SRS Required)
          _buildMenuItem(
            icon: Icons.location_on,
            title: 'Shipping Addresses',
            onTap: () => ProfileDialogs.showShippingAddresses(
              context,
              _userProfile,
                  (newAddress) {
                _addressController.text = newAddress;
                _updateProfile();
              },
            ),
          ),
          Divider(height: 1),

          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () => ProfileDialogs.showComingSoon(context, 'Notifications'),
          ),
          Divider(height: 1),

          // Feedback & Support
          _buildMenuItem(
            icon: Icons.feedback,
            title: 'Feedback & Support',
            onTap: () => AppRoutes.navigateToSupport(context),
          ),
          Divider(height: 1),

          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () => AppRoutes.navigateToHelp(context),
          ),
          Divider(height: 1),
          _buildMenuItem(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () => ProfileDialogs.showComingSoon(context, 'Privacy Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimary,
          fontWeight: iconColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _signOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  void _navigateToTab(int tabIndex) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main',
          (route) => false,
      arguments: tabIndex,
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}