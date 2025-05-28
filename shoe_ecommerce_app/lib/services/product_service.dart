import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/product.dart';

class ProductService {
  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.products}'))
          .timeout(Duration(seconds: ApiConstants.timeout));

      if (response.statusCode == 200) {
        return _convertResponseToProducts(response);
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  // Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await http
          .get(Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.products}/featured'))
          .timeout(Duration(seconds: ApiConstants.timeout));

      if (response.statusCode == 200) {
        return _convertResponseToProducts(response);
      } else {
        throw Exception(
            'Failed to load featured products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured products: $e');
    }
  }

  // Get products on sale
  Future<List<Product>> getProductsOnSale() async {
    try {
      final response = await http
          .get(Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.products}?discount_gt=0'))
          .timeout(Duration(seconds: ApiConstants.timeout));

      if (response.statusCode == 200) {
        return _convertResponseToProducts(response);
      } else {
        throw Exception(
            'Failed to load products on sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products on sale: $e');
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await http
          .get(Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.products}/category/$category'))
          .timeout(Duration(seconds: ApiConstants.timeout));

      if (response.statusCode == 200) {
        return _convertResponseToProducts(response);
      } else {
        throw Exception(
            'Failed to load products by category: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products by category: $e');
    }
  }

  // Get product by id
  Future<Product?> getProductById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.product}$id'))
          .timeout(Duration(seconds: ApiConstants.timeout));

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load product by ID: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product by ID: $e');
    }
  }

  // Search products by query
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http
          .get(Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.products}/search?q=$query'))
          .timeout(Duration(seconds: ApiConstants.timeout));

      if (response.statusCode == 200) {
        return _convertResponseToProducts(response);
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching products: $e');
    }
  }

  // Helper method to convert API response to list of products
  List<Product> _convertResponseToProducts(http.Response response) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
