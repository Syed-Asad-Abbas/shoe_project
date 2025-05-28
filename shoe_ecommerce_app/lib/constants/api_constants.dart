class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Product endpoints
  static const String products = '/products';
  static const String product = '/products/'; // for specific product with ID
  static const String categories = '/products/categories';

  // Order endpoints
  static const String orders = '/orders';
  static const String order = '/orders/'; // for specific order with ID

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';

  // Request timeout in seconds
  static const int timeout = 15;
}
