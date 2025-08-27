// File: lib/screens/admin/admin_wrapper.dart
import 'package:flutter/material.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme.dart';
import 'admin_dashboard.dart';
import 'admin_products_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_users_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_analytics_screen.dart';

class AdminWrapper extends StatefulWidget {
  final int initialIndex;

  const AdminWrapper({super.key, this.initialIndex = 0});

  @override
  State<AdminWrapper> createState() => _AdminWrapperState();
}

class _AdminWrapperState extends State<AdminWrapper> {
  late int _currentIndex;
  final PageController _pageController = PageController();

  final List<AdminTab> _tabs = [
    AdminTab(
      title: 'Dashboard',
      icon: Icons.dashboard,
      screen: AdminDashboardScreen(),
    ),
    AdminTab(
      title: 'Products',
      icon: Icons.inventory,
      screen: AdminProductsScreen(),
    ),
    AdminTab(
      title: 'Orders',
      icon: Icons.shopping_cart,
      screen: AdminOrdersScreen(),
    ),
    AdminTab(
      title: 'Users',
      icon: Icons.people,
      screen: AdminUsersScreen(),
    ),
    // AdminTab(
    //   title: 'Reviews',
    //   icon: Icons.rate_review,
    //   screen: AdminReviewsScreen(),
    // ),
    AdminTab(
      title: 'Categories',
      icon: Icons.category,
      screen: AdminCategoriesScreen(),
    ),
    AdminTab(
      title: 'Analytics',
      icon: Icons.analytics,
      screen: AdminAnalyticsScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Verify admin access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAdminAccess();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminAccess() async {
    try {
      await SupabaseAuthService.requireAdminAccess();
    } catch (e) {
      if (mounted) {
        _showAccessDeniedDialog();
      }
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(
          'You do not have administrator privileges to access this area. Please contact your system administrator.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/main');
            },
            child: Text('Back to App'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SupabaseAuthService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out of the admin panel?'),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should use mobile layout
    final isWideScreen = MediaQuery.of(context).size.width > 768;

    if (isWideScreen) {
      return _buildDesktopLayout();
    } else {
      return AdminWrapperMobile(initialIndex: _currentIndex);
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: _buildSideNavigation(),
          ),

          // Main Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                return _tabs[index].screen;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation() {
    final user = SupabaseAuthService.currentUser;

    return Column(
      children: [
        // Admin Header
        Container(
          padding: EdgeInsets.fromLTRB(24, 60, 24, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppTheme.primary,
                  size: 30,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (user?.email != null) ...[
                SizedBox(height: 4),
                Text(
                  user!.email!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 16),
            itemCount: _tabs.length,
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isSelected = _currentIndex == index;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: ListTile(
                  leading: Icon(
                    tab.icon,
                    color: isSelected ? AppTheme.primary : Colors.grey,
                    size: 24,
                  ),
                  title: Text(
                    tab.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primary.withValues(alpha: 0.1),
                  onTap: () => _onTabTapped(index),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),

        // Quick Actions
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Divider(),
              SizedBox(height: 16),

              // Go to Customer App
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/main');
                  },
                  icon: Icon(Icons.storefront, size: 18),
                  label: Text('Customer App'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Sign Out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: Icon(Icons.logout, size: 18),
                  label: Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminTab {
  final String title;
  final IconData icon;
  final Widget screen;

  const AdminTab({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

// Mobile version for smaller screens
class AdminWrapperMobile extends StatefulWidget {
  final int initialIndex;

  const AdminWrapperMobile({super.key, this.initialIndex = 0});

  @override
  State<AdminWrapperMobile> createState() => _AdminWrapperMobileState();
}

class _AdminWrapperMobileState extends State<AdminWrapperMobile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AdminTab> _tabs = [
    AdminTab(
      title: 'Dashboard',
      icon: Icons.dashboard,
      screen: AdminDashboardScreen(),
    ),
    AdminTab(
      title: 'Products',
      icon: Icons.inventory,
      screen: AdminProductsScreen(),
    ),
    AdminTab(
      title: 'Orders',
      icon: Icons.shopping_cart,
      screen: AdminOrdersScreen(),
    ),
    AdminTab(
      title: 'More',
      icon: Icons.more_horiz,
      screen: AdminMoreScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, _tabs.length - 1),
    );

    // Verify admin access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyAdminAccess();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminAccess() async {
    try {
      await SupabaseAuthService.requireAdminAccess();
    } catch (e) {
      if (mounted) {
        _showAccessDeniedDialog();
      }
    }
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(
          'You do not have administrator privileges to access this area.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/main');
            },
            child: Text('Back to App'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SupabaseAuthService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          tabs: _tabs.map((tab) {
            return Tab(
              icon: Icon(tab.icon, size: 22),
              text: tab.title,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Additional screen for mobile "More" tab
class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuthService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Admin Menu'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Admin Profile Card
          Card(
            margin: EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrator',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (user?.email != null) ...[
                          SizedBox(height: 4),
                          Text(
                            user!.email!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Management Section
          _buildSectionHeader('Management'),
          _buildMoreItem(
            context,
            'Users Management',
            Icons.people,
                () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => AdminUsersScreen(),
            )),
          ),
          // _buildMoreItem(
          //   context,
          //   'Reviews Management',
          //   Icons.rate_review,
          //       () => Navigator.push(context, MaterialPageRoute(
          //     builder: (context) => AdminReviewsScreen(),
          //   )),
          // ),
          _buildMoreItem(
            context,
            'Categories',
            Icons.category,
                () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => AdminCategoriesScreen(),
            )),
          ),
          _buildMoreItem(
            context,
            'Analytics',
            Icons.analytics,
                () => Navigator.push(context, MaterialPageRoute(
              builder: (context) => AdminAnalyticsScreen(),
            )),
          ),

          SizedBox(height: 24),
          _buildSectionHeader('Quick Actions'),
          _buildMoreItem(
            context,
            'Customer App',
            Icons.storefront,
                () => Navigator.pushReplacementNamed(context, '/main'),
          ),
          _buildMoreItem(
            context,
            'Sign Out',
            Icons.logout,
                () => _showSignOutDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMoreItem(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : AppTheme.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out of the admin panel?'),
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
      } catch (e) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}