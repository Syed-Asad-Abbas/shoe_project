import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  bool? _activeFilter;

  CustomerProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool? get activeFilter => _activeFilter;

  // Initialize and load customers
  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final customers = await _apiService.getCustomers();
      _customers = customers;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Search customers
  void searchCustomers(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by active status
  void filterByActiveStatus(bool? isActive) {
    _activeFilter = isActive;
    _applyFilters();
    notifyListeners();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredCustomers = _customers;

    // Apply active status filter
    if (_activeFilter != null) {
      _filteredCustomers = _filteredCustomers
          .where((customer) => customer.isActive == _activeFilter)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredCustomers = _filteredCustomers
          .where((customer) =>
              customer.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              customer.email
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              customer.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  // Get a specific customer by ID
  Future<Customer?> getCustomerById(String id) async {
    try {
      final customer = await _apiService.getCustomerById(id);
      return customer;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update a customer
  Future<bool> updateCustomer(Customer customer) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedCustomer = await _apiService.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index >= 0) {
        _customers[index] = updatedCustomer;
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

  // Get customer statistics
  Map<String, dynamic> getCustomerStatistics() {
    final int totalCustomers = _customers.length;

    final int activeCustomers =
        _customers.where((customer) => customer.isActive).length;

    final DateTime now = DateTime.now();
    final DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final int newThisMonth = _customers
        .where((customer) => customer.createdAt.isAfter(thirtyDaysAgo))
        .length;

    double averageOrdersPerCustomer = 0;
    if (totalCustomers > 0) {
      averageOrdersPerCustomer =
          _customers.fold(0, (sum, customer) => sum + customer.orderCount) /
              totalCustomers;
    }

    return {
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'newThisMonth': newThisMonth,
      'activePercentage': totalCustomers > 0
          ? (activeCustomers / totalCustomers * 100).toStringAsFixed(1)
          : '0',
      'averageOrders': averageOrdersPerCustomer.toStringAsFixed(1),
    };
  }

  // Reset filters
  void resetFilters() {
    _searchQuery = '';
    _activeFilter = null;
    _applyFilters();
    notifyListeners();
  }

  // Get top customers by order count
  List<Customer> getTopCustomersByOrders(int limit) {
    final sortedCustomers = List<Customer>.from(_customers);
    sortedCustomers.sort((a, b) => b.orderCount.compareTo(a.orderCount));
    return sortedCustomers.take(limit).toList();
  }

  // Get top customers by spending
  List<Customer> getTopCustomersBySpending(int limit) {
    final sortedCustomers = List<Customer>.from(_customers);
    sortedCustomers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return sortedCustomers.take(limit).toList();
  }
}
