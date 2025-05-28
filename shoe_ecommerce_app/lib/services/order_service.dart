import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class OrderService {
  final ApiService _apiService;
  final String baseUrl = ApiConstants.baseUrl;
  final http.Client _client;

  OrderService({ApiService? apiService, http.Client? client})
      : _apiService = apiService ?? ApiService(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      'x-auth-token': token ?? '',
    };
  }

  // Get all orders (for admin)
  Future<List<Order>> getAllOrders() async {
    final headers = await _getHeaders();

    final response = await _client.get(
      Uri.parse('$baseUrl/admin/orders'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders: ${response.body}');
    }
  }

  // Get orders by status (for admin)
  Future<List<Order>> getOrdersByStatus(String status) async {
    final headers = await _getHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/orders?status=$status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders by status: ${response.body}');
    }
  }

  // Get order by ID (for admin)
  Future<Order> getOrderById(String id) async {
    final headers = await _getHeaders();

    final response = await _client.get(
      Uri.parse('$baseUrl/admin/orders/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load order: ${response.body}');
    }
  }

  // Update order status (for admin)
  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    final headers = await _getHeaders();

    final response = await _client.put(
      Uri.parse('$baseUrl/admin/orders/$id/status'),
      headers: headers,
      body: jsonEncode({'status': status.index}),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  // Create new order (for admin)
  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    final headers = await _getHeaders();
    final response = await _client.post(
      Uri.parse('$baseUrl/admin/orders'),
      headers: headers,
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  // Search orders (for admin)
  Future<List<Order>> searchOrders(String query) async {
    final headers = await _getHeaders();
    final response = await _client.get(
      Uri.parse('$baseUrl/admin/orders/search?q=$query'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search orders: ${response.body}');
    }
  }

  Future<List<Order>> getRecentOrders(int limit) async {
    final headers = await _getHeaders();

    final response = await _client.get(
      Uri.parse('$baseUrl/admin/orders/recent?limit=$limit'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recent orders: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getOrderStatistics() async {
    final headers = await _getHeaders();

    final response = await _client.get(
      Uri.parse('$baseUrl/admin/orders/statistics'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load order statistics: ${response.body}');
    }
  }
}
