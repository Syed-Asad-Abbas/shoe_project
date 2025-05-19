class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Product endpoints
  static const String products = '/products';
  static const String product = '/products/'; // for specific product with ID

  // Order endpoints
  static const String orders = '/orders';
  static const String adminOrders = '/admin/orders';

  // Customer endpoints
  static const String customers = '/admin/customers';
  static const String users = '/admin/users';

  // Analytics endpoints
  static const String analytics = '/admin/analytics';
  static const String salesOverview = '/admin/analytics/sales-overview';
  static const String salesByPeriod = '/admin/analytics/sales';
  static const String topProducts = '/admin/analytics/top-products';
  static const String customerAcquisition =
      '/admin/analytics/customer-acquisition';
  static const String orderStatus = '/admin/analytics/order-status';
  static const String lowInventory = '/admin/analytics/low-inventory';

  // Authentication
  static const String tokenKey = 'auth_token';

  // Timeouts
  static const int connectionTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds
}
