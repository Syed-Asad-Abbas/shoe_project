import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _statusFilter = 'All';

  OrderProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  List<Order> get orders => _orders;
  List<Order> get filteredOrders => _filteredOrders;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  // Initialize and load orders
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final orders = await _apiService.getOrders();
      _orders = orders;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Search orders
  void searchOrders(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredOrders = _orders;

    // Apply status filter
    if (_statusFilter != 'All') {
      _filteredOrders = _filteredOrders
          .where((order) => order.status == _statusFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredOrders = _filteredOrders
          .where((order) =>
              order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.customerName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (order.customerEmail != null &&
                  order.customerEmail!
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())))
          .toList();
    }
  }

  // Get a specific order by ID
  Future<Order?> getOrderById(String id) async {
    try {
      final order = await _apiService.getOrderById(id);
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update an order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedOrder = await _apiService.updateOrderStatus(orderId, status);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = updatedOrder;
      }
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get orders statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final statistics = await _apiService.getOrderStatistics();
      return statistics;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Get recent orders (for dashboard)
  Future<List<Order>> getRecentOrders(int limit) async {
    try {
      final recentOrders = await _apiService.getRecentOrders(limit);
      return recentOrders;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Reset filters
  void resetFilters() {
    _searchQuery = '';
    _statusFilter = 'All';
    _applyFilters();
    notifyListeners();
  }

  // Get order status counts
  Map<String, int> getStatusCounts() {
    final Map<String, int> counts = {
      'Processing': 0,
      'Shipped': 0,
      'Delivered': 0,
      'Cancelled': 0,
    };

    for (final order in _orders) {
      if (counts.containsKey(order.status)) {
        counts[order.status] = (counts[order.status] ?? 0) + 1;
      }
    }

    return counts;
  }

  // Get total orders count
  int get totalOrdersCount => _orders.length;

  // Get total revenue from all orders
  double get totalRevenue {
    return _orders.fold(0, (sum, order) => sum + order.total);
  }

  // Get average order value
  double get averageOrderValue {
    if (_orders.isEmpty) return 0;
    return totalRevenue / _orders.length;
  }
}
