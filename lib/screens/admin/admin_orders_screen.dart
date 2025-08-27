// File: lib/screens/admin/admin_orders_screen.dart
import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../components/loading_widget.dart';
import '../../../components/error_widget.dart';
import '../../../components/empty_state_widget.dart';
import '../../../components/custom_app_bar.dart';
import '../../../components/price_display.dart';
import '../../../theme.dart';
import 'order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  final String? initialStatus;

  const AdminOrdersScreen({super.key, this.initialStatus});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  Map<String, int> _ordersSummary = {};

  final List<String> _statuses = [
    'all',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);

    // Set initial tab based on initialStatus
    if (widget.initialStatus != null) {
      final index = _statuses.indexOf(widget.initialStatus!);
      if (index != -1) {
        _tabController.index = index;
      }
    }

    _loadOrders();
    _loadOrdersSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders([String? status]) async {
    if (!mounted) return; // Early return if widget is disposed

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final orders = await AdminService.getAllOrders(
        status: status == 'all' ? null : status,
      );

      // Check mounted before setState after async operation
      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      // Check mounted before setState in catch block
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrdersSummary() async {
    if (!mounted) return; // Early return if widget is disposed

    try {
      final summary = await AdminService.getOrdersSummary();

      // Check mounted before setState after async operation
      if (!mounted) return;

      setState(() {
        _ordersSummary = summary;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading orders summary: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateOrderStatus(
      String orderId,
      String newStatus, {
        String? trackingNumber,
      }) async {
    if (!mounted) return; // Early return if widget is disposed

    try {
      await AdminService.updateOrderStatus(
        orderId,
        newStatus,
        trackingNumber: trackingNumber,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );

      _loadOrders(_getCurrentStatus());
      _loadOrdersSummary();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _getCurrentStatus() {
    final currentStatus = _statuses[_tabController.index];
    return currentStatus == 'all' ? null : currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Orders Management',
        subtitle: _orders.isNotEmpty ? '${_orders.length} orders' : null,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statuses.map((status) => _buildOrdersList(status)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        onTap: (index) {
          final status = _statuses[index];
          _loadOrders(status);
        },
        tabs: _statuses.map((status) {
          final count = status == 'all'
              ? _ordersSummary.values.fold<int>(0, (sum, count) => sum + count)
              : _ordersSummary[status] ?? 0;

          return Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(status.toUpperCase()),
                if (count > 0)
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    if (_isLoading) {
      return LoadingWidget(message: 'Loading orders...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error!,
        actionText: 'Retry',
        onActionPressed: () => _loadOrders(status),
      );
    }

    if (_orders.isEmpty) {
      return EmptyStateWidget(
        message: 'No ${status == 'all' ? '' : status} orders found',
        subtitle: 'Orders will appear here when customers place them',
        icon: Icons.receipt_long,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(status),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final customerName = order['profiles']?['full_name'] ?? 'Unknown Customer';
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          if (!mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order['id']),
            ),
          );

          // Check mounted after navigation returns
          if (mounted) {
            _loadOrders(_getCurrentStatus());
            _loadOrdersSummary();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order #${order['order_number'] ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Spacer(),
                            _buildStatusChip(status),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    createdAt != null
                        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                        : 'Unknown date',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Spacer(),
                  PriceDisplay(
                    price: totalAmount,
                    priceStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${(order['order_items'] as List?)?.length ?? 0} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (status == 'pending' || status == 'confirmed')
                    _buildQuickActionButtons(order),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'processing':
        color = Colors.purple;
        break;
      case 'shipped':
        color = Colors.indigo;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'returned':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'pending')
          _buildQuickActionButton(
            'Confirm',
            Icons.check,
            Colors.green,
                () => _updateOrderStatus(order['id'], 'confirmed'),
          ),
        if (status == 'confirmed')
          _buildQuickActionButton(
            'Process',
            Icons.settings,
            Colors.blue,
                () => _updateOrderStatus(order['id'], 'processing'),
          ),
        SizedBox(width: 8),
        _buildQuickActionButton(
          'View',
          Icons.visibility,
          AppTheme.primary,
              () async {
            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(orderId: order['id']),
              ),
            );

            // Check mounted after navigation returns
            if (mounted) {
              _loadOrders(_getCurrentStatus());
              _loadOrdersSummary();
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}