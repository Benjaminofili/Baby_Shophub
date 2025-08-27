// lib/providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _dashboardStats = await AdminService.getDashboardStats();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching dashboard stats: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all orders
  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await AdminService.getAllOrders(status: status);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching orders: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch all users
  Future<void> fetchUsers({String? searchQuery, String? role}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await AdminService.getAllUsers(searchQuery: searchQuery, role: role);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching users: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus, {
    String? trackingNumber,
    String? adminNotes,
    DateTime? estimatedDelivery,
  }) async {
    try {
      await AdminService.updateOrderStatus(
        orderId,
        newStatus,
        trackingNumber: trackingNumber,
        adminNotes: adminNotes,
        estimatedDelivery: estimatedDelivery,
      );

      // Refresh orders after update
      await fetchOrders();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await AdminService.updateUserRole(userId, newRole);

      // Refresh users after update
      await fetchUsers();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user role: $e');
      }
      return false;
    }
  }

  // Get sales analytics
  Future<Map<String, dynamic>> getSalesAnalytics({int days = 30}) async {
    try {
      return await AdminService.getSalesAnalytics(days: days);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sales analytics: $e');
      }
      return {};
    }
  }

  // Get inventory alerts
  Future<Map<String, dynamic>> getInventoryAlerts() async {
    try {
      return await AdminService.getInventoryAlerts();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting inventory alerts: $e');
      }
      return {};
    }
  }
}