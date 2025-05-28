import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  double _shippingCost = 0.0;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  double get shippingCost => _shippingCost;

  double get subtotal {
    return _cartItems.fold(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  double get total => subtotal + shippingCost;

  int get itemCount => _cartItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );

  Future<void> initialize() async {
    await fetchCart(forceRefresh: true);
  }

  Future<void> fetchCart({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Fetching cart (forceRefresh: $forceRefresh)');
      final cartData = await _apiService.getCart(forceRefresh: forceRefresh);
      _cartItems = cartData;
      debugPrint('Fetched ${_cartItems.length} cart items');

      // Calculate shipping cost - free over $100, otherwise $10
      _shippingCost = subtotal > 100 ? 0 : 10;
    } catch (error) {
      // Handle error
      debugPrint('Error fetching cart: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(
    String productId,
    int quantity,
    double size,
  ) async {
    try {
      debugPrint(
          'Adding to cart: productId=$productId, quantity=$quantity, size=$size');

      // First check if this product with this size is already in cart
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.product.id == productId && item.size == size.toString(),
      );

      if (existingItemIndex >= 0) {
        // If it is, just update the quantity
        await updateCartItemQuantity(
          _cartItems[existingItemIndex].id,
          _cartItems[existingItemIndex].quantity + quantity,
        );
        return;
      }

      // Otherwise, add a new item
      _isLoading = true;
      notifyListeners();

      // Pass size directly as double to API call
      final cartItems = await _apiService.addToCart(productId, quantity, size);

      // Update the cart with the new list returned from the API
      _cartItems = cartItems;
      debugPrint('Updated cart now has ${_cartItems.length} items');

      // Recalculate shipping cost
      _shippingCost = subtotal > 100 ? 0 : 10;

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error adding to cart: $error');
      rethrow; // Rethrow to let the UI handle it
    }
  }

  Future<void> removeCartItem(String cartItemId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use updateCart with quantity 0 to remove item
      await _apiService.updateCart(cartItemId, 0);

      // Remove from local list
      _cartItems.removeWhere((item) => item.id == cartItemId);

      // Recalculate shipping cost
      _shippingCost = subtotal > 100 ? 0 : 10;

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error removing from cart: $error');

      // Try to remove from local list anyway
      _cartItems.removeWhere((item) => item.id == cartItemId);
      notifyListeners();

      rethrow;
    }
  }

  Future<void> updateCartItemQuantity(
      String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeCartItem(cartItemId);
        return;
      }

      _isLoading = true;
      notifyListeners();

      // Update cart through API
      final updatedCart = await _apiService.updateCart(cartItemId, newQuantity);

      // Update local cart with returned data
      _cartItems = updatedCart;

      // Recalculate shipping cost
      _shippingCost = subtotal > 100 ? 0 : 10;

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating cart item quantity: $error');

      // Try to update locally anyway
      final itemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (itemIndex >= 0) {
        _cartItems[itemIndex].quantity = newQuantity;
        notifyListeners();
      }

      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear cart on server side
      await _apiService.clearCart();

      // Clear local cache
      _cartItems = [];
      _shippingCost = 0;

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error clearing cart: $error');

      // Clear local list anyway
      _cartItems = [];
      notifyListeners();

      rethrow;
    }
  }
}
