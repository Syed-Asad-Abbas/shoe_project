import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = false;
  String _error = '';
  int _retryAttempts = 0;
  final int _maxRetryAttempts = 3;
  bool _isRetrying = false;

  // Cache management variables
  DateTime? _lastProductFetch;
  DateTime? _lastFeaturedProductFetch;
  final Duration _refreshInterval = const Duration(minutes: 30);

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isRetrying => _isRetrying;

  // Check if the cache is stale and needs refresh
  bool get _isProductCacheStale {
    if (_lastProductFetch == null) return true;
    return DateTime.now().difference(_lastProductFetch!) > _refreshInterval;
  }

  bool get _isFeaturedProductCacheStale {
    if (_lastFeaturedProductFetch == null) return true;
    return DateTime.now().difference(_lastFeaturedProductFetch!) >
        _refreshInterval;
  }

  Future<void> fetchProducts(
      {String? category, String? search, bool forceRefresh = false}) async {
    // Skip if we're already loading and not forcing refresh
    if (_isLoading && !forceRefresh) return;

    // If we have data and cache is not stale, return cached data
    if (!forceRefresh && !_isProductCacheStale && _products.isNotEmpty) {
      debugPrint('Using cached product data from provider');
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      List<Product> fetchedProducts = [];

      if (category != null) {
        debugPrint(
            'Fetching products by category: $category (forceRefresh: $forceRefresh)');
        fetchedProducts = await _apiService.getProductsByCategory(category,
            forceRefresh: forceRefresh);
      } else if (search != null && search.isNotEmpty) {
        debugPrint('Searching products: $search (forceRefresh: $forceRefresh)');
        fetchedProducts = await _apiService.searchProducts(search,
            forceRefresh: forceRefresh);
      } else {
        debugPrint('Fetching all products (forceRefresh: $forceRefresh)');
        fetchedProducts =
            await _apiService.getProducts(forceRefresh: forceRefresh);
      }

      // Update the products list with fetched data
      _products = fetchedProducts;
      _lastProductFetch = DateTime.now();
      debugPrint('Fetched ${_products.length} products');

      // Reset retry attempts on success
      _retryAttempts = 0;

      // If no products were loaded and we're not at max attempts, try again with forceRefresh
      if (_products.isEmpty && !forceRefresh) {
        debugPrint('No products found, trying again with forced refresh');
        return fetchProducts(
            category: category, search: search, forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Fetch products error: $e');
      _error = 'Failed to load products: $e';

      // Auto-retry logic
      if (_retryAttempts < _maxRetryAttempts && !_isRetrying) {
        _retryAttempts++;
        _isRetrying = true;
        debugPrint(
            'Auto-retrying fetch products attempt $_retryAttempts/$_maxRetryAttempts');
        notifyListeners();

        await Future.delayed(Duration(seconds: _retryAttempts));
        _isRetrying = false;
        return fetchProducts(
            category: category, search: search, forceRefresh: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedProducts({bool forceRefresh = false}) async {
    // Skip if we're already loading and not forcing refresh
    if (_isLoading && !forceRefresh) return;

    // If we have data and cache is not stale, return cached data
    if (!forceRefresh &&
        !_isFeaturedProductCacheStale &&
        _featuredProducts.isNotEmpty) {
      debugPrint('Using cached featured product data from provider');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Fetching featured products (forceRefresh: $forceRefresh)');
      _featuredProducts =
          await _apiService.getFeaturedProducts(forceRefresh: forceRefresh);
      _lastFeaturedProductFetch = DateTime.now();
      debugPrint('Fetched ${_featuredProducts.length} featured products');

      // Reset retry attempts on success
      _retryAttempts = 0;

      // If no featured products were loaded and we're not at max attempts, try again with forceRefresh
      if (_featuredProducts.isEmpty && !forceRefresh) {
        debugPrint(
            'No featured products found, trying again with forced refresh');
        return fetchFeaturedProducts(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Fetch featured products error: $e');
      _error = 'Failed to load featured products: $e';

      // Auto-retry logic
      if (_retryAttempts < _maxRetryAttempts && !_isRetrying) {
        _retryAttempts++;
        _isRetrying = true;
        debugPrint(
            'Auto-retrying fetch featured products attempt $_retryAttempts/$_maxRetryAttempts');
        notifyListeners();

        await Future.delayed(Duration(seconds: _retryAttempts));
        _isRetrying = false;
        return fetchFeaturedProducts(forceRefresh: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Product> getProductById(String id, {bool forceRefresh = false}) async {
    try {
      debugPrint('Getting product by ID: $id (forceRefresh: $forceRefresh)');

      // First check if it's in our local lists to avoid API call
      if (!forceRefresh) {
        final localProduct = _findProductInLocalCache(id);
        if (localProduct != null) {
          debugPrint('Found product $id in local provider cache');
          return localProduct;
        }
      }

      // If not in local cache, fetch from API (which has its own caching)
      final product =
          await _apiService.getProductById(id, forceRefresh: forceRefresh);
      return product;
    } catch (e) {
      debugPrint('Get product by id error: $e');
      _error = 'Failed to load product details: $e';

      // Last resort - try to find in local cache
      final localProduct = _findProductInLocalCache(id);
      if (localProduct != null) {
        debugPrint('Found product $id in local cache as fallback');
        return localProduct;
      }

      rethrow;
    }
  }

  // Helper to find a product in the local cache
  Product? _findProductInLocalCache(String id) {
    try {
      // Check products list
      final product = _products.firstWhere((p) => p.id == id);
      return product;
    } catch (_) {
      try {
        // Check featured products list
        final product = _featuredProducts.firstWhere((p) => p.id == id);
        return product;
      } catch (_) {
        // Not found in any list
        return null;
      }
    }
  }

  // Add a refresh method to easily refresh all data
  Future<void> refreshAllData() async {
    debugPrint('Refreshing all product data');
    _error = '';
    // Reset retry counter on manual refresh
    _retryAttempts = 0;

    // Clear API cache as well to ensure fresh data
    _apiService.clearProductCache();

    await fetchProducts(forceRefresh: true);
    await fetchFeaturedProducts(forceRefresh: true);
  }

  // Method to prefetch product details before navigating to detail screen
  Future<Product?> prefetchProductDetails(String id) async {
    try {
      // Don't set loading state for prefetch
      final product = await _apiService.getProductById(id, forceRefresh: false);
      return product;
    } catch (e) {
      debugPrint('Prefetch product details error: $e');
      return null;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Initialize products data
  Future<void> initialize() async {
    debugPrint(
        'Initializing product provider - auto-loading products from local server');
    _apiService
        .clearProductCache(); // Clear cache to ensure fresh data from localhost

    // Always force refresh on first load to ensure we're using the local server
    await fetchProducts(forceRefresh: true);
    await fetchFeaturedProducts(forceRefresh: true);
  }
}
