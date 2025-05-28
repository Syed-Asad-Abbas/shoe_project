class Constants {
  // API URLs
  static const String apiUrl = 'http://localhost:3000/api/v1';

  // App Settings
  static const String appName = 'Shoe Store';
  static const int splashDuration = 2; // in seconds

  // Network Settings
  static const int apiTimeoutSeconds = 15;
  static const int maxRetryAttempts = 3;
  static const int connectionRetryDelaySeconds = 2;

  // Validation
  static const int minPasswordLength = 6;

  // Storage Keys
  static const String tokenKey = 'token';
  static const String userKey = 'user';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String cartKey = 'cart';
  static const String favoriteKey = 'favorites';

  // Error Messages
  static const String networkErrorMessage =
      'Unable to connect to the server. Please check your internet connection and try again.';
  static const String authErrorMessage =
      'Authentication failed. Please check your credentials and try again.';
  static const String unexpectedErrorMessage =
      'An unexpected error occurred. Please try again later.';
  static const String connectionTimeoutMessage =
      'Connection timed out. Please check your internet connection and try again.';
  static const String serverErrorMessage =
      'The server encountered an error processing your request. Please try again later.';
}

// API routes
class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'http://localhost:3000/api/v1';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String loginFirebase = '/auth/login/firebase';
  static const String registerFirebase = '/auth/register/firebase';

  // Product endpoints
  static const String products = '/products';
  static const String featuredProducts = '/products/featured';
  static const String searchProducts = '/products/search';

  // Cart endpoints
  static const String cart = '/users/cart';

  // Order endpoints
  static const String orders = '/orders';
  static const String adminOrders = '/admin/orders';

  // Customer endpoints
  static const String customers = '/admin/customers';

  // Settings endpoints
  static const String settings = '/admin/settings';

  // Analytics endpoints
  static const String analytics = '/admin/analytics';
  static const String salesOverview = '/admin/analytics/sales-overview';
  static const String salesByPeriod = '/admin/analytics/sales';
  static const String topProducts = '/admin/analytics/top-products';
  static const String customerAcquisition =
      '/admin/analytics/customer-acquisition';
  static const String orderStatus = '/admin/analytics/order-status';
  static const String lowInventory = '/admin/analytics/low-inventory';
}
