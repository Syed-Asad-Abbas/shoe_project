import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../constants/api_constants.dart';

class ApiService {
  final String baseUrl = ApiConstants.baseUrl;
  final http.Client client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  ApiService({http.Client? client}) : client = client ?? http.Client();

  // Get auth token from secure storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: ApiConstants.tokenKey);
  }

  // Create auth headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'x-auth-token': token ?? '',
    };
  }

  // Admin authentication
  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    try {
      final response = await client.post(
        Uri.parse('${baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save token to secure storage
        await _secureStorage.write(
            key: ApiConstants.tokenKey, value: data['token']);

        return data;
      } else {
        _logger.e('Failed to login: ${response.body}');
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Login error: $e');
      throw Exception('Login error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _secureStorage.delete(key: ApiConstants.tokenKey);
  }

  // Product APIs
  Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.products}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        _logger.e('Failed to load products: ${response.body}');
        throw Exception('Failed to load products');
      }
    } catch (e) {
      _logger.e('Error fetching products: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.products}?id=$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        // Handle case where API returns an array
        if (data is List) {
          if (data.isEmpty) {
            throw Exception('Product not found');
          }
          // Find the product with matching id
          final productData = data.firstWhere(
            (item) => item['_id'] == id || item['id'] == id,
            orElse: () => data.first, // Fallback to first item if id not found
          );
          return Product.fromJson(productData);
        }

        // Handle case where API returns a single object
        return Product.fromJson(data);
      } else {
        _logger.e('Failed to load product with id: $id, ${response.body}');
        throw Exception('Failed to load product with id: $id');
      }
    } catch (e) {
      _logger.e('Error fetching product: $e');
      throw Exception('Error fetching product: $e');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final headers = await _getHeaders();
      final response = await client.post(
        Uri.parse('${baseUrl}${ApiConstants.products}'),
        headers: headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to create product: ${response.body}');
        throw Exception('Failed to create product');
      }
    } catch (e) {
      _logger.e('Error creating product: $e');
      throw Exception('Error creating product: $e');
    }
  }

  Future<Product> updateProduct(String id, Product product) async {
    try {
      final headers = await _getHeaders();
      final response = await client.put(
        Uri.parse('${baseUrl}${ApiConstants.product}$id'),
        headers: headers,
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to update product: ${response.body}');
        throw Exception('Failed to update product');
      }
    } catch (e) {
      _logger.e('Error updating product: $e');
      throw Exception('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.delete(
        Uri.parse('${baseUrl}${ApiConstants.product}$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        _logger.e('Failed to delete product: ${response.body}');
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      _logger.e('Error deleting product: $e');
      throw Exception('Error deleting product: $e');
    }
  }

  // Order APIs
  Future<List<Order>> getAllOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.adminOrders}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = jsonDecode(response.body);
        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        _logger.e('Failed to load orders: ${response.body}');
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      _logger.e('Error fetching orders: $e');
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<Order> getOrderById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.adminOrders}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to load order with id: $id, ${response.body}');
        throw Exception('Failed to load order with id: $id');
      }
    } catch (e) {
      _logger.e('Error fetching order: $e');
      throw Exception('Error fetching order: $e');
    }
  }

  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final headers = await _getHeaders();
      final response = await client.patch(
        Uri.parse('${baseUrl}${ApiConstants.adminOrders}/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status.index}),
      );

      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to update order status: ${response.body}');
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      _logger.e('Error updating order status: $e');
      throw Exception('Error updating order status: $e');
    }
  }

  // Customer APIs
  Future<List<User>> getCustomers() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.customers}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> customersJson = jsonDecode(response.body);
        return customersJson.map((json) => User.fromJson(json)).toList();
      } else {
        _logger.e('Failed to load customers: ${response.body}');
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      _logger.e('Error fetching customers: $e');
      throw Exception('Error fetching customers: $e');
    }
  }

  // Users API
  Future<List<User>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.users}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        _logger.e('Failed to load users: ${response.body}');
        throw Exception('Failed to load users');
      }
    } catch (e) {
      _logger.e('Error fetching users: $e');
      throw Exception('Error fetching users: $e');
    }
  }

  Future<User> getUserById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.users}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to load user with id: $id, ${response.body}');
        throw Exception('Failed to load user with id: $id');
      }
    } catch (e) {
      _logger.e('Error fetching user: $e');
      throw Exception('Error fetching user: $e');
    }
  }

  Future<User> getCustomerById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.customers}/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to load customer with id: $id, ${response.body}');
        throw Exception('Failed to load customer with id: $id');
      }
    } catch (e) {
      _logger.e('Error fetching customer: $e');
      throw Exception('Error fetching customer: $e');
    }
  }

  // Analytics APIs
  Future<Map<String, dynamic>> getSalesOverview() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.salesOverview}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('Failed to load sales overview: ${response.body}');
        throw Exception('Failed to load sales overview');
      }
    } catch (e) {
      _logger.e('Error fetching sales overview: $e');
      throw Exception('Error fetching sales overview: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSalesData(String period) async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.salesByPeriod}?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> salesJson = jsonDecode(response.body);
        return salesJson.cast<Map<String, dynamic>>();
      } else {
        _logger.e('Failed to load sales data: ${response.body}');
        throw Exception('Failed to load sales data');
      }
    } catch (e) {
      _logger.e('Error fetching sales data: $e');
      throw Exception('Error fetching sales data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.topProducts}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        return productsJson.cast<Map<String, dynamic>>();
      } else {
        _logger.e('Failed to load top products: ${response.body}');
        throw Exception('Failed to load top products');
      }
    } catch (e) {
      _logger.e('Error fetching top products: $e');
      throw Exception('Error fetching top products: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerAcquisition() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.customerAcquisition}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        _logger.e('Failed to load customer acquisition data: ${response.body}');
        throw Exception('Failed to load customer acquisition data');
      }
    } catch (e) {
      _logger.e('Error fetching customer acquisition data: $e');
      throw Exception('Error fetching customer acquisition data: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderStatusDistribution() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.orderStatus}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('Failed to load order status distribution: ${response.body}');
        throw Exception('Failed to load order status distribution');
      }
    } catch (e) {
      _logger.e('Error fetching order status distribution: $e');
      throw Exception('Error fetching order status distribution: $e');
    }
  }

  Future<List<Product>> getLowInventoryProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await client.get(
        Uri.parse('${baseUrl}${ApiConstants.lowInventory}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = jsonDecode(response.body);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else {
        _logger.e('Failed to load low inventory products: ${response.body}');
        throw Exception('Failed to load low inventory products');
      }
    } catch (e) {
      _logger.e('Error fetching low inventory products: $e');
      throw Exception('Error fetching low inventory products: $e');
    }
  }
}
