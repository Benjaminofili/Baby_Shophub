// File: lib/screens/admin/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import '../../../services/admin_service.dart';
import '../../../components/loading_widget.dart';
import '../../../components/error_widget.dart';
import '../../../components/custom_app_bar.dart';
import '../../../components/price_display.dart';
import '../../../theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _salesAnalytics;
  List<Map<String, dynamic>> _topSellingProducts = [];
  List<Map<String, dynamic>> _lowPerformingProducts = [];

  int _selectedPeriod = 30; // days
  final List<int> _periodOptions = [7, 30, 90];
  final List<String> _periodLabels = ['7 Days', '30 Days', '90 Days'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all analytics data
      final futures = await Future.wait([
        AdminService.getSalesAnalytics(days: _selectedPeriod),
        AdminService.getTopSellingProducts(days: _selectedPeriod),
        AdminService.getLowPerformingProducts(days: _selectedPeriod),
      ]);

      setState(() {
        _salesAnalytics = futures[0] as Map<String, dynamic>;
        _topSellingProducts = futures[1] as List<Map<String, dynamic>>;
        _lowPerformingProducts = futures[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changePeriod(int days) {
    setState(() {
      _selectedPeriod = days;
    });
    _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Analytics & Reports',
        subtitle: 'Last ${_periodLabels[_periodOptions.indexOf(
            _selectedPeriod)]}',
        actions: [
          PopupMenuButton<int>(
            onSelected: _changePeriod,
            itemBuilder: (context) =>
                _periodOptions.map((days) {
                  return PopupMenuItem(
                    value: days,
                    child: Row(
                      children: [
                        Icon(
                          _selectedPeriod == days ? Icons.check : Icons
                              .calendar_today,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(_periodLabels[_periodOptions.indexOf(days)]),
                      ],
                    ),
                  );
                }).toList(),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.date_range),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesOverview(),
                _buildTopProducts(),
                _buildPerformanceInsights(),
              ],
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
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        tabs: [
          Tab(text: 'SALES OVERVIEW'),
          Tab(text: 'TOP PRODUCTS'),
          Tab(text: 'INSIGHTS'),
        ],
      ),
    );
  }

  Widget _buildSalesOverview() {
    if (_isLoading) {
      return LoadingWidget(message: 'Loading analytics...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: _error!,
        actionText: 'Retry',
        onActionPressed: _loadAnalyticsData,
      );
    }

    final analytics = _salesAnalytics!;
    final totalSales = (analytics['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = analytics['total_orders'] as int? ?? 0;
    final avgOrderValue = (analytics['average_order_value'] as num?)
        ?.toDouble() ?? 0.0;
    final dailySales = analytics['daily_sales'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSalesCards(totalSales, totalOrders, avgOrderValue),
            SizedBox(height: 24),
            _buildSalesChart(dailySales),
            SizedBox(height: 24),
            _buildRevenueBreakdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCards(double totalSales, int totalOrders,
      double avgOrderValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sales Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                PriceDisplay(
                  price: totalSales,
                  priceStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ).toString(),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Orders',
                totalOrders.toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildMetricCard(
          'Average Order Value',
          '₦${avgOrderValue.toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.purple,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title,
      String value,
      IconData icon,
      Color color, {
        bool isWide = false,
      }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.trending_up, size: 16, color: Colors.green),
            ],
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isWide ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(Map<String, dynamic> dailySales) {
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
            'Daily Sales Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          // Simple chart representation
          Container(
            height: 200,
            child: dailySales.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No sales data available',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dailySales.length,
              itemBuilder: (context, index) {
                final date = dailySales.keys.elementAt(index);
                final sales = (dailySales[date] as num).toDouble();
                final maxSales = dailySales.values
                    .map((e) => (e as num).toDouble())
                    .reduce((a, b) => a > b ? a : b);
                final height = maxSales > 0 ? (sales / maxSales) * 150 : 0.0;

                return Container(
                  margin: EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '₦${sales.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        date.substring(5), // Show MM-DD
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
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
            'Revenue Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          _buildBreakdownItem('Completed Orders', 85, Colors.green),
          _buildBreakdownItem('Pending Orders', 10, Colors.orange),
          _buildBreakdownItem('Cancelled Orders', 5, Colors.red),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int percentage, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            '$percentage%',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    if (_isLoading) {
      return LoadingWidget(message: 'Loading top products...');
    }

    if (_topSellingProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No sales data available',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _topSellingProducts.length,
        itemBuilder: (context, index) {
          final product = _topSellingProducts[index];
          return _buildProductCard(product, index + 1, true);
        },
      ),
    );
  }

  Widget _buildPerformanceInsights() {
    if (_isLoading) {
      return LoadingWidget(message: 'Loading insights...');
    }

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInsightsHeader(),
            SizedBox(height: 16),
            if (_lowPerformingProducts.isNotEmpty) ...[
              _buildLowPerformingSection(),
              SizedBox(height: 24),
            ],
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsHeader() {
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
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Performance Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Based on the last ${_periodLabels[_periodOptions.indexOf(
                _selectedPeriod)]}, here are key insights about your business performance.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowPerformingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products Needing Attention',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        ...(_lowPerformingProducts.take(5).map((product) {
          return _buildProductCard(product, null, false);
        }).toList()),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int? rank,
      bool isTopSelling) {
    final productName = product['product_name'] ?? 'Unknown Product';
    final productImage = product['product_image'];
    final totalSales = isTopSelling
        ? (product['total_quantity'] as int? ?? 0)
        : (product['total_sales'] as int? ?? 0);
    final revenue = isTopSelling ? (product['total_revenue'] as num?)
        ?.toDouble() ?? 0.0 : null;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            if (rank != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
            ],
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: productImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  productImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.image, color: Colors.grey),
                ),
              )
                  : Icon(Icons.image, color: Colors.grey),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    isTopSelling
                        ? '$totalSales units sold'
                        : '$totalSales sales',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (revenue != null)
              PriceDisplay(
                price: revenue,
                priceStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
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
          Row(
            children: [
              Icon(Icons.recommend, color: AppTheme.primary, size: 24),
              SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildRecommendationItem(
            Icons.trending_up,
            'Promote Top Sellers',
            'Feature your best-selling products in marketing campaigns',
            Colors.green,
          ),
          _buildRecommendationItem(
            Icons.inventory,
            'Stock Management',
            'Monitor inventory levels for popular items to avoid stockouts',
            Colors.blue,
          ),
          _buildRecommendationItem(
            Icons.price_change,
            'Pricing Strategy',
            'Review pricing for low-performing products',
            Colors.orange,
          ),
          _buildRecommendationItem(
            Icons.campaign,
            'Marketing Focus',
            'Create targeted campaigns for underperforming categories',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(IconData icon,
      String title,
      String description,
      Color color,) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return AppTheme.primary;
    }
  }
}