import 'dart:convert';
import '../models/customer.dart';
import '../models/user.dart';
import 'api_service.dart';

class CustomerService {
  final ApiService _apiService;

  CustomerService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<Customer>> getCustomers() async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final token = await _apiService.getToken();
      if (token != null) {
        headers['x-auth-token'] = token;
      }

      final response = await _apiService.client.get(
        Uri.parse('${_apiService.baseUrl}/api/v1/admin/customers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<Customer> getCustomerById(String id) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final token = await _apiService.getToken();
      if (token != null) {
        headers['x-auth-token'] = token;
      }

      final response = await _apiService.client.get(
        Uri.parse('${_apiService.baseUrl}/api/v1/admin/customers/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Customer.fromJson(data);
      } else {
        throw Exception('Failed to load customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load customer: $e');
    }
  }

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final token = await _apiService.getToken();
      if (token != null) {
        headers['x-auth-token'] = token;
      }

      final response = await _apiService.client.post(
        Uri.parse('${_apiService.baseUrl}/api/v1/admin/customers'),
        headers: headers,
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Customer.fromJson(data);
      } else {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final token = await _apiService.getToken();
      if (token != null) {
        headers['x-auth-token'] = token;
      }

      final response = await _apiService.client.put(
        Uri.parse(
            '${_apiService.baseUrl}/api/v1/admin/customers/${customer.id}'),
        headers: headers,
        body: json.encode(customer.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Customer.fromJson(data);
      } else {
        throw Exception('Failed to update customer: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final token = await _apiService.getToken();
      if (token != null) {
        headers['x-auth-token'] = token;
      }

      final response = await _apiService.client.delete(
        Uri.parse('${_apiService.baseUrl}/api/v1/admin/customers/$id'),
        headers: headers,
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      final token = await _apiService.getToken();
      if (token != null) {
        headers['x-auth-token'] = token;
      }

      final response = await _apiService.client.get(
        Uri.parse(
            '${_apiService.baseUrl}/api/v1/admin/customers/search?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search customers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }
}
