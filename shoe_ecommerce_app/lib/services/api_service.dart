import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl = ApiConstants.baseUrl;
  final http.Client client;
  // Increased timeout duration for slow connections
  final Duration _timeout = const Duration(seconds: 20);
  // Cache expiration time - 30 minutes
  final Duration _cacheExpiration = const Duration(minutes: 30);
  // Default retry count
  final int _maxRetryCount = 3;

  // In-memory cache for products
  static Map<String, dynamic> _productCache = {};
  static DateTime _lastCacheCleanup = DateTime.now();

  ApiService({http.Client? client}) : client = client ?? http.Client();

  // Get auth token from storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Create auth headers
  Future<Map<String, String>> _getHeaders({bool forceRefresh = false}) async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'x-auth-token': token ?? '',
    };

    // Add cache control headers if forceRefresh is true
    if (forceRefresh) {
      headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
    }

    return headers;
  }

  // Clean up expired cache entries periodically
  void _cleanupCache() {
    final now = DateTime.now();
    if (now.difference(_lastCacheCleanup) > const Duration(minutes: 5)) {
      debugPrint('Cleaning up API cache...');
      _productCache.removeWhere((key, value) {
        return now.difference(value['timestamp']).inMinutes >
            _cacheExpiration.inMinutes;
      });
      _lastCacheCleanup = now;
    }
  }

  // Helper method to create a request with timeout and retry logic
  Future<http.Response> _makeRequest(Future<http.Response> request,
      {int retryCount = 0}) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      debugPrint(
          'Request timed out (Attempt ${retryCount + 1}/$_maxRetryCount)');
      if (retryCount < _maxRetryCount - 1) {
        // Exponential backoff for retries
        final delay = Duration(milliseconds: 500 * (retryCount + 1));
        debugPrint('Retrying after ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    } catch (e) {
      debugPrint(
          'Request failed with error: $e (Attempt ${retryCount + 1}/$_maxRetryCount)');
      if (retryCount < _maxRetryCount - 1) {
        // Exponential backoff for retries
        final delay = Duration(milliseconds: 500 * (retryCount + 1));
        debugPrint('Retrying after ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        return _makeRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  // Product APIs with improved caching
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    _cleanupCache();

    final cacheKey = 'all_products';
    // Check cache first unless force refresh
    if (!forceRefresh && _productCache.containsKey(cacheKey)) {
      final cachedData = _productCache[cacheKey];
      final timestamp = cachedData['timestamp'] as DateTime;

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        debugPrint('Using cached products data');
        return cachedData['data'] as List<Product>;
      }
    }

    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl/products');

      // Add cache-busting parameter if force refresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri;

      debugPrint('Fetching products from $finalUri');
      final request = client.get(finalUri, headers: headers);
      final response = await _makeRequest(request);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        debugPrint('Successfully fetched ${productsJson.length} products');

        final products =
            productsJson.map((json) => Product.fromJson(json)).toList();

        // Store in cache
        _productCache[cacheKey] = {
          'data': products,
          'timestamp': DateTime.now(),
        };

        return products;
      } else {
        debugPrint(
            'Failed to load products: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');

      // Return mock products for demonstration if API fails
      debugPrint('Falling back to mock products');
      final mockProducts = _getMockProducts();

      // Cache mock data to avoid repeated failures
      _productCache[cacheKey] = {
        'data': mockProducts,
        'timestamp': DateTime.now(),
      };

      return mockProducts;
    }
  }

  // Rest of the mock products implementation remains the same
  List<Product> _getMockProducts() {
    return [
      Product(
        id: 'p1001',
        name: 'Nike Air Max 270',
        description:
            'The Nike Air Max 270 delivers unrivaled comfort with its large window and fresh design.',
        price: 150.00,
        imageUrl:
            'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/skwgyqrbfzhu6uyeh0gg/air-max-270-shoes-2V5C4m.png',
        category: 'Running',
        sizes: [7.0, 8.0, 9.0, 10.0, 11.0],
        colors: ['Black', 'White', 'Red'],
        inStock: true,
        discount: 10,
        isFavorite: false,
        rating: 4.5,
        reviewCount: 120,
        stockQuantity: 25,
        featured: true,
      ),
      Product(
        id: 'p1002',
        name: 'Adidas Ultraboost',
        description:
            'Ultraboost with Primeknit upper that adapts to the shape of your foot for adaptive support and comfort.',
        price: 180.00,
        imageUrl:
            'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/fbaf991a78bc4896a3e9aad6009a2fa8_9366/Ultraboost_22_Shoes_Black_GZ0127_01_standard.jpg',
        category: 'Running',
        sizes: [8.0, 9.0, 10.0, 11.0, 12.0],
        colors: ['Black', 'White', 'Blue'],
        inStock: true,
        discount: 0,
        isFavorite: false,
        rating: 4.7,
        reviewCount: 98,
        stockQuantity: 18,
        featured: true,
      ),
      Product(
        id: 'p1003',
        name: 'Puma RS-X',
        description:
            'The RS-X features a bulky design with running-inspired cushioning in the midsole.',
        price: 110.00,
        imageUrl:
            'https://images.puma.com/image/upload/f_auto,q_auto,b_rgb:fafafa,w_2000,h_2000/global/369579/01/sv01/fnd/PNA/fmt/png/RS-X-Reinvention-Men\'s-Sneakers',
        category: 'Casual',
        sizes: [7.0, 8.0, 9.0, 10.0],
        colors: ['Yellow', 'Blue', 'Green'],
        inStock: true,
        discount: 15,
        isFavorite: false,
        rating: 4.2,
        reviewCount: 67,
        stockQuantity: 12,
        featured: true,
      ),
      Product(
        id: 'p1004',
        name: 'Converse Chuck Taylor',
        description:
            'The classic Chuck Taylor All Star high top with canvas upper and rubber sole.',
        price: 60.00,
        imageUrl:
            'https://www.converse.com/dw/image/v2/BCZC_PRD/on/demandware.static/-/Sites-cnv-master-catalog/default/dw8e716fed/images/a_08/M9160_A_08X1.jpg',
        category: 'Casual',
        sizes: [6.0, 7.0, 8.0, 9.0, 10.0, 11.0],
        colors: ['Black', 'White', 'Red', 'Navy'],
        inStock: true,
        discount: 0,
        isFavorite: false,
        rating: 4.6,
        reviewCount: 112,
        stockQuantity: 7,
        featured: true,
      ),
      Product(
        id: 'p1005',
        name: 'Jordan Air 1',
        description:
            'The iconic Jordan Air 1 basketball shoes with premium leather upper.',
        price: 160.00,
        imageUrl:
            'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/f094af40-f82f-4fb9-a246-e031bf6fc411/air-jordan-1-mid-shoes-86f1ZW.png',
        category: 'Basketball',
        sizes: [8.0, 9.0, 10.0, 11.0, 12.0],
        colors: ['Red', 'Black', 'White'],
        inStock: true,
        discount: 0,
        isFavorite: false,
        rating: 4.8,
        reviewCount: 145,
        stockQuantity: 15,
        featured: true,
      ),
      Product(
        id: 'p1006',
        name: 'New Balance 574',
        description:
            'Classic New Balance 574 with ENCAP cushioning for all-day comfort.',
        price: 80.00,
        imageUrl: 'https://nb.scene7.com/is/image/NB/ml574evn_nb_02_i',
        category: 'Casual',
        sizes: [7.0, 8.0, 9.0, 10.0, 11.0],
        colors: ['Grey', 'Navy', 'Black'],
        inStock: true,
        discount: 0,
        isFavorite: false,
        rating: 4.3,
        reviewCount: 89,
        stockQuantity: 22,
        featured: true,
      ),
      Product(
        id: 'p1007',
        name: 'Vans Old Skool',
        description: 'The classic Vans Old Skool with signature side stripe.',
        price: 65.00,
        imageUrl:
            'https://images.vans.com/is/image/VansBrand/VN000D3HY28-HERO?\$583x583\$',
        category: 'Casual',
        sizes: [7.0, 8.0, 9.0, 10.0, 11.0],
        colors: ['Black', 'White', 'Red'],
        inStock: true,
        discount: 0,
        isFavorite: false,
        rating: 4.5,
        reviewCount: 102,
        stockQuantity: 18,
        featured: false,
      ),
      Product(
        id: 'p1008',
        name: 'Under Armour HOVR',
        description:
            'Under Armour HOVR running shoes with responsive cushioning.',
        price: 120.00,
        imageUrl:
            'https://underarmour.scene7.com/is/image/Underarmour/3023648-403_DEFAULT?rp=standard-0pad|pdpMainDesktop&scl=1&fmt=jpg&qlt=85&resMode=sharp2&cache=on,on&bgc=f0f0f0&wid=566&hei=708&size=566,708',
        category: 'Running',
        sizes: [8.0, 9.0, 10.0, 11.0],
        colors: ['Blue', 'Black', 'Grey'],
        inStock: true,
        discount: 0,
        isFavorite: false,
        rating: 4.4,
        reviewCount: 76,
        stockQuantity: 14,
        featured: true,
      ),
    ];
  }

  // Optimized product by ID with more efficient caching
  Future<Product> getProductById(String id, {bool forceRefresh = false}) async {
    _cleanupCache();

    final cacheKey = 'product_$id';
    // Check cache first unless force refresh
    if (!forceRefresh && _productCache.containsKey(cacheKey)) {
      final cachedData = _productCache[cacheKey];
      final timestamp = cachedData['timestamp'] as DateTime;

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        debugPrint('Using cached product data for ID: $id');
        return cachedData['data'] as Product;
      }
    }

    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl/products/$id');

      // Add cache-busting parameter if force refresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri;

      debugPrint('Fetching product with ID: $id');
      final request = client.get(finalUri, headers: headers);
      final response = await _makeRequest(request);

      if (response.statusCode == 200) {
        debugPrint('Successfully fetched product with ID: $id');
        final product = Product.fromJson(jsonDecode(response.body));

        // Store in cache
        _productCache[cacheKey] = {
          'data': product,
          'timestamp': DateTime.now(),
        };

        return product;
      } else {
        throw Exception('Failed to load product with id: $id');
      }
    } catch (e) {
      debugPrint('Error fetching product: $e');

      // Try to find the product in existing lists before giving up
      final localProduct = _findProductInLocalCache(id);
      if (localProduct != null) {
        debugPrint('Found product $id in local cache, using that instead');

        // Store in product ID cache too
        _productCache[cacheKey] = {
          'data': localProduct,
          'timestamp': DateTime.now(),
        };

        return localProduct;
      }

      rethrow;
    }
  }

  // Helper to find a product in the local cache
  Product? _findProductInLocalCache(String id) {
    // Check first in all_products cache
    if (_productCache.containsKey('all_products')) {
      final allProducts =
          _productCache['all_products']['data'] as List<Product>;
      try {
        return allProducts.firstWhere((p) => p.id == id);
      } catch (_) {
        // Not found in all_products
      }
    }

    // Check in featured_products cache
    if (_productCache.containsKey('featured_products')) {
      final featuredProducts =
          _productCache['featured_products']['data'] as List<Product>;
      try {
        return featuredProducts.firstWhere((p) => p.id == id);
      } catch (_) {
        // Not found in featured_products
      }
    }

    // Not found in any cache
    return null;
  }

  // Auth APIs - User Profile
  Future<User> getUserProfile({bool forceRefresh = false}) async {
    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl/auth/profile');

      // Add cache-busting parameter if force refresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri;

      debugPrint('Fetching user profile from $finalUri');
      final request = client.get(finalUri, headers: headers);
      final response = await _makeRequest(request);

      if (response.statusCode == 200) {
        debugPrint('Successfully fetched user profile');
        return User.fromJson(jsonDecode(response.body));
      } else {
        debugPrint(
            'Failed to get profile: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get profile: ${response.body}');
      }
    } catch (e) {
      debugPrint('Get user profile error: $e');
      throw Exception('Failed to fetch profile: Please check your connection');
    }
  }

  // Fetch products by category with improved caching
  Future<List<Product>> getProductsByCategory(String category,
      {bool forceRefresh = false}) async {
    _cleanupCache();

    final cacheKey = 'category_$category';
    // Check cache first unless force refresh
    if (!forceRefresh && _productCache.containsKey(cacheKey)) {
      final cachedData = _productCache[cacheKey];
      final timestamp = cachedData['timestamp'] as DateTime;

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        debugPrint('Using cached products data for category: $category');
        return cachedData['data'] as List<Product>;
      }
    }

    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl/products/category/$category');

      // Add cache-busting parameter if force refresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri;

      final request = client.get(finalUri, headers: headers);
      final response = await _makeRequest(request);

      if (response.statusCode == 200) {
        debugPrint('Successfully fetched products for category: $category');
        final List<dynamic> productsJson = jsonDecode(response.body);
        final products =
            productsJson.map((json) => Product.fromJson(json)).toList();

        // Store in cache
        _productCache[cacheKey] = {
          'data': products,
          'timestamp': DateTime.now(),
        };

        return products;
      } else {
        throw Exception(
            'Failed to load products by category: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching products by category: $e');

      // Return filtered mock products if API fails
      final mockProductsByCategory = _getMockProducts()
          .where((product) => product.category == category)
          .toList();

      // Cache the result
      _productCache[cacheKey] = {
        'data': mockProductsByCategory,
        'timestamp': DateTime.now(),
      };

      return mockProductsByCategory;
    }
  }

  // Fetch featured products with improved caching
  Future<List<Product>> getFeaturedProducts({bool forceRefresh = false}) async {
    _cleanupCache();

    final cacheKey = 'featured_products';
    // Check cache first unless force refresh
    if (!forceRefresh && _productCache.containsKey(cacheKey)) {
      final cachedData = _productCache[cacheKey];
      final timestamp = cachedData['timestamp'] as DateTime;

      // Check if cache is still valid
      if (DateTime.now().difference(timestamp) < _cacheExpiration) {
        debugPrint('Using cached featured products data');
        return cachedData['data'] as List<Product>;
      }
    }

    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl/products/featured');

      // Add cache-busting parameter if force refresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri;

      debugPrint('Fetching featured products from $finalUri');
      final request = client.get(finalUri, headers: headers);
      final response = await _makeRequest(request);

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        debugPrint(
            'Successfully fetched ${productsJson.length} featured products');

        if (productsJson.isEmpty) {
          debugPrint(
              'No featured products found in API response, using mock data');
          final mockFeatured =
              _getMockProducts().where((product) => product.featured).toList();

          // Cache the mock result
          _productCache[cacheKey] = {
            'data': mockFeatured,
            'timestamp': DateTime.now(),
          };

          return mockFeatured;
        }

        final products =
            productsJson.map((json) => Product.fromJson(json)).toList();

        // Store in cache
        _productCache[cacheKey] = {
          'data': products,
          'timestamp': DateTime.now(),
        };

        return products;
      } else {
        debugPrint(
            'Failed to load featured products: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to load featured products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching featured products: $e');

      // Return mock featured products if API fails
      debugPrint('Falling back to mock featured products');
      final mockFeatured =
          _getMockProducts().where((product) => product.featured).toList();

      // Cache the mock result
      _productCache[cacheKey] = {
        'data': mockFeatured,
        'timestamp': DateTime.now(),
      };

      return mockFeatured;
    }
  }

  // Search products with improved caching
  Future<List<Product>> searchProducts(String query,
      {bool forceRefresh = false}) async {
    _cleanupCache();

    final cacheKey = 'search_$query';
    // Check cache first unless force refresh - shorter expiration for searches
    if (!forceRefresh && _productCache.containsKey(cacheKey)) {
      final cachedData = _productCache[cacheKey];
      final timestamp = cachedData['timestamp'] as DateTime;

      // Check if cache is still valid (10 minutes for search results)
      if (DateTime.now().difference(timestamp) < const Duration(minutes: 10)) {
        debugPrint('Using cached search results for: $query');
        return cachedData['data'] as List<Product>;
      }
    }

    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl/products');

      // Add cache-busting parameter if forceRefresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              'search': query,
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri.replace(queryParameters: {'search': query});

      final request = client.get(finalUri, headers: headers);
      final response = await _makeRequest(request);

      if (response.statusCode == 200) {
        debugPrint('Successfully searched products for: $query');
        final List<dynamic> productsJson = jsonDecode(response.body);
        final products =
            productsJson.map((json) => Product.fromJson(json)).toList();

        // Store in cache
        _productCache[cacheKey] = {
          'data': products,
          'timestamp': DateTime.now(),
        };

        return products;
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching products: $e');

      // Search in mock products if API fails
      final lowercaseQuery = query.toLowerCase();
      final mockSearchResults = _getMockProducts()
          .where((product) =>
              product.name.toLowerCase().contains(lowercaseQuery) ||
              product.description.toLowerCase().contains(lowercaseQuery) ||
              product.category.toLowerCase().contains(lowercaseQuery))
          .toList();

      // Cache the result
      _productCache[cacheKey] = {
        'data': mockSearchResults,
        'timestamp': DateTime.now(),
      };

      return mockSearchResults;
    }
  }

  // Clear all product caches - useful for logout or forced refresh
  void clearProductCache() {
    debugPrint('Clearing all product caches');
    _productCache.clear();
  }

  // Cart APIs
  Future<List<CartItem>> getCart({bool forceRefresh = false}) async {
    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final uri = Uri.parse('$baseUrl${ApiConstants.cart}');

      // Add cache-busting parameter if force refresh
      final finalUri = forceRefresh
          ? uri.replace(queryParameters: {
              '_t': DateTime.now().millisecondsSinceEpoch.toString()
            })
          : uri;

      debugPrint('Fetching cart from: $finalUri');
      final response = await client
          .get(finalUri, headers: headers)
          .timeout(_timeout, onTimeout: () {
        debugPrint('Cart fetch timeout. Using cached or mock data.');
        throw TimeoutException(
            'The connection has timed out, please try again later.');
      });

      if (response.statusCode == 200) {
        debugPrint('Successfully fetched cart items');
        final List<dynamic> cartItems = jsonDecode(response.body);
        debugPrint('Cart response contains ${cartItems.length} items');
        return await Future.wait(cartItems.map((json) async {
          // Get product details separately if needed
          final productId = json['product'] is String
              ? json['product']
              : json['product']['_id'];
          Product product;

          if (json['product'] is String) {
            try {
              product = await getProductById(productId);
            } catch (e) {
              debugPrint('Error fetching product $productId for cart: $e');
              // If product details can't be fetched, use a placeholder
              product = Product(
                id: productId,
                name: 'Unknown Product',
                description: '',
                price: double.tryParse(json['price'].toString()) ?? 0.0,
                imageUrl: '',
                category: '',
                sizes: [],
                colors: [],
                inStock: true,
              );
            }
          } else {
            product = Product.fromJson(json['product']);
          }

          return CartItem.fromJson(json, productData: product);
        }).toList());
      } else if (response.statusCode == 401) {
        debugPrint(
            'Unauthorized request to cart (401). User may need to log in again.');
        throw Exception('Unauthorized: Please login to view your cart');
      } else {
        debugPrint(
            'Failed to load cart. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');

      // Get cart data from SharedPreferences as a fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString('cartItems');
        if (cartJson != null && cartJson.isNotEmpty) {
          debugPrint('Using cached cart data from SharedPreferences');
          final List<dynamic> items = jsonDecode(cartJson);
          return await Future.wait(items.map((item) async {
            final productId = item['product'];
            Product product;

            try {
              product = await getProductById(productId);
            } catch (e) {
              product = Product(
                id: productId,
                name: 'Product',
                description: '',
                price: double.tryParse(item['price'].toString()) ?? 0.0,
                imageUrl: '',
                category: '',
                sizes: [],
                colors: [],
                inStock: true,
              );
            }

            return CartItem(
              id: item['id'],
              product: product,
              size: item['size'],
              quantity: item['quantity'],
              price: double.parse(item['price'].toString()),
            );
          }).toList());
        }
      } catch (err) {
        debugPrint('Error reading cart from SharedPreferences: $err');
      }

      // Only return empty list, not mock data
      return [];
    }
  }

  Future<List<CartItem>> addToCart(
      String productId, int quantity, double size) async {
    try {
      // First get product details to use in local cache
      final product = await getProductById(productId);
      final cartItemId = 'cart_${DateTime.now().millisecondsSinceEpoch}';

      final headers = await _getHeaders();
      debugPrint(
          'Adding to cart: productId=$productId, quantity=$quantity, size=$size');

      final response = await client
          .post(
            Uri.parse('$baseUrl${ApiConstants.cart}'),
            headers: headers,
            body: jsonEncode({
              'productId': productId,
              'quantity': quantity,
              'size': size.toString(),
            }),
          )
          .timeout(_timeout);

      debugPrint('Add to cart response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Successfully added item to cart');
        return getCart(forceRefresh: true); // Force refresh to get updated cart
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized: User needs to login to add to cart');
        throw Exception('Unauthorized: Please login to add to cart');
      } else {
        debugPrint(
            'Failed to add to cart: ${response.statusCode} - ${response.body}');

        // If API fails, store the cart item locally
        final newCartItem = CartItem(
          id: cartItemId,
          product: product,
          size: size.toString(),
          quantity: quantity,
          price: product.price,
        );

        // Get existing items from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> cartItems = [];
        final cartJson = prefs.getString('cartItems');

        if (cartJson != null && cartJson.isNotEmpty) {
          cartItems = List<Map<String, dynamic>>.from(jsonDecode(cartJson));
        }

        // Add new item
        cartItems.add({
          'id': cartItemId,
          'product': productId,
          'size': size.toString(),
          'quantity': quantity,
          'price': product.price,
        });

        // Save back to SharedPreferences
        await prefs.setString('cartItems', jsonEncode(cartItems));

        // Return updated cart with the new item
        final currentCart = await getCart();
        return [...currentCart, newCartItem];
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');

      // Try to add locally if possible
      try {
        final product = await getProductById(productId);
        final cartItemId = 'cart_${DateTime.now().millisecondsSinceEpoch}';

        final prefs = await SharedPreferences.getInstance();
        List<Map<String, dynamic>> cartItems = [];
        final cartJson = prefs.getString('cartItems');

        if (cartJson != null && cartJson.isNotEmpty) {
          cartItems = List<Map<String, dynamic>>.from(jsonDecode(cartJson));
        }

        // Add new item
        cartItems.add({
          'id': cartItemId,
          'product': productId,
          'size': size.toString(),
          'quantity': quantity,
          'price': product.price,
        });

        // Save back to SharedPreferences
        await prefs.setString('cartItems', jsonEncode(cartItems));

        // Get updated cart
        final currentCart = await getCart();
        final newCartItem = CartItem(
          id: cartItemId,
          product: product,
          size: size.toString(),
          quantity: quantity,
          price: product.price,
        );

        return [...currentCart, newCartItem];
      } catch (err) {
        debugPrint('Error saving cart to local storage: $err');
        return getCart(); // Return current cart
      }
    }
  }

  Future<List<CartItem>> updateCart(String cartItemId, int quantity) async {
    try {
      final headers = await _getHeaders();
      debugPrint(
          'Updating cart item: cartItemId=$cartItemId, quantity=$quantity');

      final response = await client
          .put(
            Uri.parse('$baseUrl${ApiConstants.cart}/$cartItemId'),
            headers: headers,
            body: jsonEncode({
              'quantity': quantity,
            }),
          )
          .timeout(_timeout);

      debugPrint('Update cart response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('Successfully updated cart item');
        return getCart(forceRefresh: true); // Force refresh to get updated cart
      } else if (response.statusCode == 401) {
        debugPrint('Unauthorized: User needs to login to update cart');
        throw Exception('Unauthorized: Please login to update your cart');
      } else {
        debugPrint(
            'Failed to update cart: ${response.statusCode} - ${response.body}');

        // Update locally if API fails
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString('cartItems');

        if (cartJson != null && cartJson.isNotEmpty) {
          List<Map<String, dynamic>> cartItems =
              List<Map<String, dynamic>>.from(jsonDecode(cartJson));

          // Find and update the item
          for (var i = 0; i < cartItems.length; i++) {
            if (cartItems[i]['id'] == cartItemId) {
              if (quantity <= 0) {
                cartItems.removeAt(i);
              } else {
                cartItems[i]['quantity'] = quantity;
              }
              break;
            }
          }

          // Save back to SharedPreferences
          await prefs.setString('cartItems', jsonEncode(cartItems));
        }

        return getCart(); // Get updated local cart
      }
    } catch (e) {
      debugPrint('Error updating cart: $e');

      // Try to update locally
      try {
        final prefs = await SharedPreferences.getInstance();
        final cartJson = prefs.getString('cartItems');

        if (cartJson != null && cartJson.isNotEmpty) {
          List<Map<String, dynamic>> cartItems =
              List<Map<String, dynamic>>.from(jsonDecode(cartJson));

          // Find and update the item
          for (var i = 0; i < cartItems.length; i++) {
            if (cartItems[i]['id'] == cartItemId) {
              if (quantity <= 0) {
                cartItems.removeAt(i);
              } else {
                cartItems[i]['quantity'] = quantity;
              }
              break;
            }
          }

          // Save back to SharedPreferences
          await prefs.setString('cartItems', jsonEncode(cartItems));
        }
      } catch (err) {
        debugPrint('Error updating local cart: $err');
      }

      return getCart(); // Return current cart
    }
  }

  Future<void> clearCart() async {
    try {
      final headers = await _getHeaders();
      final response = await client
          .delete(
            Uri.parse('$baseUrl${ApiConstants.cart}'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('Successfully cleared cart on server');
      } else {
        debugPrint('Failed to clear cart on server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error clearing server cart: $e');
    }

    // Always clear local cache regardless of server response
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cartItems');
      debugPrint('Local cart cache cleared');
    } catch (e) {
      debugPrint('Error clearing local cart cache: $e');
    }
  }

  // Order APIs
  Future<List<Order>> getOrders() async {
    try {
      final headers = await _getHeaders();
      debugPrint('Fetching orders from: $baseUrl${ApiConstants.orders}');

      final response = await client
          .get(
            Uri.parse('$baseUrl${ApiConstants.orders}'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('Orders API response: ${response.body}');
        final List<dynamic> ordersJson = jsonDecode(response.body);
        final orders = ordersJson.map((json) => Order.fromJson(json)).toList();
        return orders;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login to view your orders');
      } else {
        debugPrint(
            'Failed to load orders. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      // Return empty list instead of mock data
      return [];
    }
  }

  Future<Order> getOrderById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl${ApiConstants.orders}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login to view this order');
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching order: $e');
      // Return mock order if API fails
      return _getMockOrders().firstWhere(
        (order) => order.id == id,
        orElse: () => _getMockOrders().first,
      );
    }
  }

  Future<Order> createOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    try {
      final headers = await _getHeaders();
      // Try with both localhost and 10.0.2.2 (for Android emulator)
      final baseUrls = [
        baseUrl,
        baseUrl.replaceAll('localhost', '10.0.2.2'),
        'http://10.0.2.2:3000/api/v1',
        'http://localhost:3000/api/v1'
      ];

      Exception? lastException;

      // Try multiple base URLs in case some don't work
      for (final url in baseUrls) {
        try {
          debugPrint('Trying to create order at: $url${ApiConstants.orders}');
          debugPrint(
              'Order payload: items=${items.length}, total=$totalAmount');

          final response = await client
              .post(
                Uri.parse('$url${ApiConstants.orders}'),
                headers: headers,
                body: jsonEncode({
                  'items': items
                      .map((item) => {
                            'productId': item.product.id,
                            'quantity': item.quantity,
                            'size': item.size,
                            'price': item.price,
                          })
                      .toList(),
                  'totalAmount': totalAmount,
                  'shippingAddress': shippingAddress,
                  'paymentMethod': paymentMethod,
                }),
              )
              .timeout(const Duration(seconds: 5));

          debugPrint('Order creation response: ${response.statusCode}');

          if (response.statusCode == 201 || response.statusCode == 200) {
            debugPrint('Order created successfully: ${response.body}');
            return Order.fromJson(jsonDecode(response.body));
          } else {
            debugPrint(
                'Failed to create order: ${response.statusCode} - ${response.body}');
            lastException =
                Exception('Failed to create order: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error creating order with URL $url: $e');
          lastException = Exception('Connection error: ${e.toString()}');
          // Continue to try next URL
          continue;
        }
      }

      // If we get here, all URLs failed
      throw lastException ?? Exception('Failed to connect to the server');
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }

  // Mock orders for when API is unavailable
  List<Order> _getMockOrders() {
    final products = _getMockProducts();

    return [
      Order(
        id: 'o1001',
        customerId: 'user123',
        customerName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 123-456-7890',
        items: [
          CartItem(
            id: '1',
            product: products[0],
            size: '9.0',
            quantity: 1,
            price: products[0].price,
          ),
          CartItem(
            id: '2',
            product: products[2],
            size: '10.0',
            quantity: 1,
            price: products[2].price,
          ),
        ],
        totalAmount: products[0].price + products[2].price,
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: OrderStatus.delivered,
        shippingAddress: '123 Main St, New York, NY 10001, USA',
        paymentMethod: 'Credit Card',
      ),
      Order(
        id: 'o1002',
        customerId: 'user123',
        customerName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 123-456-7890',
        items: [
          CartItem(
            id: '3',
            product: products[1],
            size: '8.0',
            quantity: 1,
            price: products[1].price,
          ),
        ],
        totalAmount: products[1].price,
        date: DateTime.now().subtract(const Duration(days: 10)),
        status: OrderStatus.delivered,
        shippingAddress: '123 Main St, New York, NY 10001, USA',
        paymentMethod: 'PayPal',
      ),
      Order(
        id: 'o1003',
        customerId: 'user123',
        customerName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 123-456-7890',
        items: [
          CartItem(
            id: '4',
            product: products[3],
            size: '9.0',
            quantity: 1,
            price: products[3].price,
          ),
          CartItem(
            id: '5',
            product: products[1],
            size: '10.0',
            quantity: 1,
            price: products[1].price,
          ),
        ],
        totalAmount: products[3].price + products[1].price,
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: OrderStatus.processing,
        shippingAddress: '123 Main St, New York, NY 10001, USA',
        paymentMethod: 'Credit Card',
      ),
    ];
  }

  // Favorites APIs
  Future<List<String>> toggleFavorite(String productId) async {
    final headers = await _getHeaders();
    final response = await client.post(
      Uri.parse('$baseUrl/users/favorites'),
      headers: headers,
      body: jsonEncode({
        'productId': productId,
      }),
    );

    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to toggle favorite: ${response.body}');
    }
  }

  // Process order
  Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> items,
    required String address,
    required double total,
    required String paymentMethod,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': items.map((item) => item.toJson()).toList(),
          'address': address,
          'total': total,
          'paymentMethod': paymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      throw Exception('Error placing order: $e');
    }
  }

  // Add these auth methods after the getUserProfile method

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    try {
      final request = client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final response = await _makeRequest(request);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Save token to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        return data;
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      throw Exception(
          'Registration failed: Please check your connection and try again');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('Attempting login for $email to $baseUrl/auth/login');

      final request = client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final response = await _makeRequest(request);
      debugPrint('Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Login successful, token received');

        // Save token to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);

        return data;
      } else {
        debugPrint(
            'Login failed with status code: ${response.statusCode}, body: ${response.body}');
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      throw Exception(
          'Login failed: Please check your connection and try again');
    }
  }
}
