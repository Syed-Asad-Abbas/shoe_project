import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService;
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedPeriod = 'monthly';

  // Analytics data
  Map<String, dynamic> _salesOverview = {};
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _customersByRegion = [];
  List<Map<String, dynamic>> _categoryPerformance = [];
  List<Map<String, dynamic>> _customerAcquisition = [];

  AnalyticsProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;
  Map<String, dynamic> get salesOverview => _salesOverview;
  List<Map<String, dynamic>> get salesData => _salesData;
  List<Map<String, dynamic>> get customersByRegion => _customersByRegion;
  List<Map<String, dynamic>> get categoryPerformance => _categoryPerformance;
  List<Map<String, dynamic>> get customerAcquisition => _customerAcquisition;

  // Initialize and load analytics data
  Future<void> loadAnalyticsData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Load all the required analytics data
      final salesOverview = await _apiService.getSalesOverview();
      final salesData = await _apiService.getSalesByPeriod(_selectedPeriod);
      final customersByRegion = await _apiService.getCustomersByRegion();
      final categoryPerformance = await _apiService.getCategoryPerformance();
      final customerAcquisition = await _apiService.getCustomerAcquisition();

      // Update state
      _salesOverview = salesOverview;
      _salesData = salesData;
      _customersByRegion = customersByRegion;
      _categoryPerformance = categoryPerformance;
      _customerAcquisition = customerAcquisition;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Change the time period for the sales data
  void changePeriod(String period) {
    if (period != _selectedPeriod) {
      _selectedPeriod = period;
      _updateSalesData();
      notifyListeners();
    }
  }

  // Update sales data for the selected period
  Future<void> _updateSalesData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final salesData = await _apiService.getSalesByPeriod(_selectedPeriod);
      _salesData = salesData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get revenue growth percentage
  double getRevenueGrowth() {
    return _salesOverview['salesChange'] ?? 0.0;
  }

  // Get orders growth percentage
  double getOrdersGrowth() {
    return _salesOverview['ordersChange'] ?? 0.0;
  }

  // Get average order value growth percentage
  double getAverageOrderValueGrowth() {
    return _salesOverview['aovChange'] ?? 0.0;
  }

  // Get conversion rate growth percentage
  double getConversionRateGrowth() {
    return _salesOverview['conversionChange'] ?? 0.0;
  }

  // Get total revenue
  double getTotalRevenue() {
    return _salesOverview['totalSales'] ?? 0.0;
  }

  // Get total orders
  int getTotalOrders() {
    return _salesOverview['ordersCount'] ?? 0;
  }

  // Get average order value
  double getAverageOrderValue() {
    return _salesOverview['averageOrderValue'] ?? 0.0;
  }

  // Get conversion rate
  double getConversionRate() {
    return _salesOverview['conversionRate'] ?? 0.0;
  }

  // Get top-selling category
  String getTopSellingCategory() {
    if (_categoryPerformance.isEmpty) return 'N/A';

    // Sort by revenue and return the top category
    var sorted = List<Map<String, dynamic>>.from(_categoryPerformance);
    sorted.sort((a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num));

    return sorted.first['category'] ?? 'N/A';
  }

  // Get primary customer region
  String getPrimaryCustomerRegion() {
    if (_customersByRegion.isEmpty) return 'N/A';

    // Sort by percentage and return the top region
    var sorted = List<Map<String, dynamic>>.from(_customersByRegion);
    sorted.sort(
        (a, b) => (b['percentage'] as num).compareTo(a['percentage'] as num));

    return sorted.first['region'] ?? 'N/A';
  }

  // Get customer growth rate
  double getCustomerGrowthRate() {
    if (_customerAcquisition.length < 2) return 0.0;

    try {
      final current = _customerAcquisition.last['customers'] as num;
      final previous = _customerAcquisition[_customerAcquisition.length - 2]
          ['customers'] as num;

      if (previous == 0) return 100.0; // If there were no customers before

      return ((current - previous) / previous) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}
