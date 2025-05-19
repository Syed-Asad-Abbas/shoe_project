import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _currentCategory = 'All';

  ProductProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get currentCategory => _currentCategory;

  // Initialize and load products
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final products = await _apiService.getProducts();
      _products = products;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String category) {
    _currentCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredProducts = _products;

    // Apply category filter
    if (_currentCategory != 'All') {
      _filteredProducts = _filteredProducts
          .where((product) => product.category == _currentCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  // Add a new product
  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newProduct = await _apiService.addProduct(product);
      _products.add(newProduct);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update an existing product
  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedProduct = await _apiService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = updatedProduct;
      }
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _apiService.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get a product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final product = await _apiService.getProductById(id);
      return product;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Get unique categories
  Set<String> getCategories() {
    return _products.map((product) => product.category).toSet();
  }

  // Reset filters
  void resetFilters() {
    _searchQuery = '';
    _currentCategory = 'All';
    _applyFilters();
    notifyListeners();
  }
}
