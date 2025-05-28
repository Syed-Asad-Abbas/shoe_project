import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  // Initialize provider by fetching orders - called at app startup
  Future<void> initialize() async {
    debugPrint('Initializing OrderProvider');
    await fetchOrders();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch orders directly from API with no fallback to mock data
      final fetchedOrders = await _apiService.getOrders();
      _orders = fetchedOrders;
      debugPrint('Fetched ${_orders.length} orders from API');
    } catch (error) {
      debugPrint('Error fetching orders from API: $error');
      // Don't use mock data, just keep the list empty on error
      _orders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    required String customerId,
    required String customerName,
    required String email,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Always create a real order through the API
      final order = await _apiService.createOrder(
        items: items,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
      );

      // If successful, add to local list and return
      if (order != null) {
        // Add to beginning of list to show newest first
        _orders.insert(0, order);
        debugPrint('Successfully placed order: ${order.id}');
        _isLoading = false;
        notifyListeners();
        return order;
      }

      throw Exception('Failed to place order');
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error placing order: $error');
      rethrow; // Propagate error to UI for proper handling
    }
  }

  // Helper method to generate mock orders for demonstration
  List<Order> _getMockOrders() {
    return [
      Order(
        id: '1001',
        customerId: 'user123',
        customerName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 123-456-7890',
        items: [
          CartItem(
            id: '1',
            product: _getMockProduct('1', 'Nike Air Max 270', 150.0,
                'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/skwgyqrbfzhu6uyeh0gg/air-max-270-shoes-2V5C4m.png'),
            size: '9',
            quantity: 1,
            price: 150.0,
          ),
          CartItem(
            id: '2',
            product: _getMockProduct('3', 'Jordan Retro 1', 170.0,
                'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/f094af40-f82f-4fb9-a246-e031bf6fc411/air-jordan-1-mid-shoes-86f1ZW.png'),
            size: '10',
            quantity: 1,
            price: 170.0,
          ),
        ],
        totalAmount: 320.0,
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: OrderStatus.delivered,
        shippingAddress: '123 Main St, New York, NY 10001, USA',
        paymentMethod: 'Credit Card',
      ),
      Order(
        id: '1002',
        customerId: 'user123',
        customerName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 123-456-7890',
        items: [
          CartItem(
            id: '3',
            product: _getMockProduct('2', 'Adidas Ultraboost', 180.0,
                'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/fbaf991a78bc4896a3e9aad6009a2fa8_9366/Ultraboost_22_Shoes_Black_GZ0127_01_standard.jpg'),
            size: '8',
            quantity: 1,
            price: 180.0,
          ),
        ],
        totalAmount: 180.0,
        date: DateTime.now().subtract(const Duration(days: 10)),
        status: OrderStatus.delivered,
        shippingAddress: '123 Main St, New York, NY 10001, USA',
        paymentMethod: 'PayPal',
      ),
      Order(
        id: '1003',
        customerId: 'user123',
        customerName: 'John Doe',
        email: 'john@example.com',
        phone: '+1 123-456-7890',
        items: [
          CartItem(
            id: '4',
            product: _getMockProduct('4', 'Puma RS-X', 110.0,
                'https://images.puma.com/image/upload/f_auto,q_auto,b_rgb:fafafa,w_2000,h_2000/global/369579/01/sv01/fnd/PNA/fmt/png/RS-X-Reinvention-Men\'s-Sneakers'),
            size: '9',
            quantity: 1,
            price: 110.0,
          ),
        ],
        totalAmount: 110.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: OrderStatus.processing,
        shippingAddress: '123 Main St, New York, NY 10001, USA',
        paymentMethod: 'Credit Card',
      ),
    ];
  }

  // Helper to create mock product for cart items
  Product _getMockProduct(
      String id, String name, double price, String imageUrl) {
    return Product(
      id: id,
      name: name,
      description: 'Mock product description',
      price: price,
      imageUrl: imageUrl,
      category: 'Shoes',
      sizes: [7.0, 8.0, 9.0, 10.0, 11.0],
      colors: ['Black', 'White', 'Red'],
      inStock: true,
      discount: 0,
      isFavorite: false,
      rating: 4.5,
      reviewCount: 100,
      stockQuantity: 50,
      featured: false,
    );
  }
}
