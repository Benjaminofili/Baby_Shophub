// File: lib/screens/admin/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../services/admin_service.dart';
import '../../../components/loading_widget.dart';
import '../../../components/error_widget.dart';
import '../../../components/empty_state_widget.dart';
import '../../../components/custom_app_bar.dart';
import '../../../theme.dart';
import 'user_details_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  Map<String, int> _userCounts = {};
  String? _searchQuery;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadUserCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Updated _loadUsers method in AdminUsersScreen
  Future<void> _loadUsers([String? role]) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await AdminService.getAllUsers(
        searchQuery: _searchQuery,
        role: role == 'all' ? null : role,
      );

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

// Updated _loadUserCounts method
  Future<void> _loadUserCounts() async {
    try {
      final counts = await AdminService.getUsersCountByRole();

      if (mounted) {
        setState(() {
          _userCounts = counts;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading user counts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCurrentRole() {
    switch (_tabController.index) {
      case 0:
        return 'all';
      case 1:
        return 'user';
      case 2:
        return 'admin';
      default:
        return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Users Management',
        subtitle: _users.isNotEmpty ? '${_users.length} users' : null,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList('all'),
                _buildUsersList('user'),
                _buildUsersList('admin'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search users by name or email...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = null;
              });
              _loadUsers(_getCurrentRole());
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppTheme.primary),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.isEmpty ? null : value;
          });
        },
        onSubmitted: (_) => _loadUsers(_getCurrentRole()),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        onTap: (index) {
          final role = _getCurrentRole();
          _loadUsers(role);
        },
        tabs: [
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ALL USERS'),
                if (_userCounts.values.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _userCounts.values.fold<int>(0, (sum, count) => sum + count).toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CUSTOMERS'),
                if (_userCounts['user'] != null && _userCounts['user']! > 0)
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _userCounts['user'].toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ADMINS'),
                if (_userCounts['admin'] != null && _userCounts['admin']! > 0)
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _userCounts['admin'].toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(String role) {
    if (_isLoading) {
      return LoadingWidget(message: 'Loading users...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error!,
        actionText: 'Retry',
        onActionPressed: () => _loadUsers(role),
      );
    }

    if (_users.isEmpty) {
      return EmptyStateWidget(
        message: 'No ${role == 'all' ? '' : role} users found',
        subtitle: 'Users will appear here when they register',
        icon: Icons.people,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(role),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'user';
    final isAdmin = role == 'admin';
    final fullName = user['full_name'] ?? 'No Name';
    final email = user['email'] ?? 'No Email';
    final createdAt = DateTime.tryParse(user['created_at'] ?? '');

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailsScreen(userId: user['id']),
          ),
        ).then((_) => _loadUsers(_getCurrentRole())),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAdmin ? Colors.red.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.1),
                ),
                child: user['avatar_url'] != null
                    ? ClipOval(
                  child: Image.network(
                    user['avatar_url'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(fullName, isAdmin),
                  ),
                )
                    : _buildDefaultAvatar(fullName, isAdmin),
              ),
              SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAdmin ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isAdmin ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          createdAt != null
                              ? 'Joined ${createdAt.day}/${createdAt.month}/${createdAt.year}'
                              : 'Join date unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Spacer(),
                        if (user['phone'] != null && user['phone'].toString().isNotEmpty) ...[
                          Icon(Icons.phone, size: 14, color: AppTheme.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            user['phone'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String name, bool isAdmin) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final color = isAdmin ? Colors.red : AppTheme.primary;

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}