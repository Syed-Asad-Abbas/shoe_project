import 'dart:convert';
import '../models/product.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class AnalyticsService {
  final ApiService _apiService;
  final http.Client _client;
  final String baseUrl = ApiConstants.baseUrl;

  AnalyticsService({ApiService? apiService, http.Client? client})
      : _apiService = apiService ?? ApiService(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _apiService.getToken();
    return {
      'Content-Type': 'application/json',
      'x-auth-token': token ?? '',
    };
  }

  // Get sales overview data
  Future<Map<String, dynamic>> getSalesOverview() async {
    try {
      final headers = await _getHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl${ApiConstants.salesOverview}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load sales overview');
      }
    } catch (e) {
      return _getMockSalesOverview();
    }
  }

  // Get sales by period data
  Future<List<Map<String, dynamic>>> getSalesByPeriod(String period) async {
    try {
      final headers = await _getHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl${ApiConstants.salesByPeriod}?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load sales by period');
      }
    } catch (e) {
      return _getMockSalesByPeriod(period);
    }
  }

  // Get top products data
  Future<List<Map<String, dynamic>>> getTopProducts() async {
    try {
      final headers = await _getHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl${ApiConstants.topProducts}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load top products');
      }
    } catch (e) {
      return _getMockTopSellingProducts();
    }
  }

  // Get customer acquisition data
  Future<List<Map<String, dynamic>>> getCustomerAcquisition() async {
    try {
      final headers = await _getHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl${ApiConstants.customerAcquisition}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load customer acquisition data');
      }
    } catch (e) {
      return _getMockCustomerAcquisition();
    }
  }

  // Get order status data
  Future<Map<String, dynamic>> getOrderStatus() async {
    try {
      final headers = await _getHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl${ApiConstants.orderStatus}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load order status data');
      }
    } catch (e) {
      return _getMockOrderStatusDistribution();
    }
  }

  // Get low inventory products
  Future<List<Product>> getLowInventoryProducts() async {
    try {
      final headers = await _getHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl${ApiConstants.lowInventory}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load low inventory products');
      }
    } catch (e) {
      return _getMockLowInventoryProducts();
    }
  }

  // Mock data methods
  Map<String, dynamic> _getMockSalesOverview() {
    return {
      'totalSales': 12500.0,
      'ordersCount': 47,
      'averageOrderValue': 265.95,
      'conversionRate': 3.2,
      'dailyChange': 12.5,
      'weeklyChange': 8.7,
      'monthlyChange': 15.3
    };
  }

  List<Map<String, dynamic>> _getMockSalesByPeriod(String period) {
    if (period == 'daily') {
      // Last 7 days
      return List.generate(7, (index) {
        final date = DateTime.now().subtract(Duration(days: 6 - index));
        return {
          'date': date.toString().substring(0, 10),
          'sales': 1000 + (index * 200) + (Random().nextDouble() * 500)
        };
      });
    } else if (period == 'weekly') {
      // Last 4 weeks
      return List.generate(4, (index) {
        final date = DateTime.now().subtract(Duration(days: (3 - index) * 7));
        return {
          'date': date.toString().substring(0, 10),
          'sales': 5000 + (index * 1000) + (Random().nextDouble() * 2000)
        };
      });
    } else {
      // Last 6 months
      return List.generate(6, (index) {
        final date = DateTime.now().subtract(Duration(days: (5 - index) * 30));
        return {
          'date': date.toString().substring(0, 7),
          'sales': 20000 + (index * 2000) + (Random().nextDouble() * 5000)
        };
      });
    }
  }

  List<Map<String, dynamic>> _getMockTopSellingProducts() {
    return [
      {
        'id': '1',
        'name': 'Nike Air Max 270',
        'sales': 38,
        'revenue': 5700.0,
        'imageUrl':
            'https://static.nike.com/a/images/t_PDP_1280_v1/f_auto,q_auto:eco/skwgyqrbfzhu6uyeh0gg/air-max-270-shoes-2V5C4m.png',
      },
      {
        'id': '2',
        'name': 'Adidas Ultraboost',
        'sales': 32,
        'revenue': 5760.0,
        'imageUrl':
            'https://assets.adidas.com/images/h_840,f_auto,q_auto,fl_lossy,c_fill,g_auto/fbaf991a78bc4896a3e9aad6009a2fa8_9366/Ultraboost_22_Shoes_Black_GZ0127_01_standard.jpg',
      },
      {
        'id': '3',
        'name': 'Puma RS-X',
        'sales': 28,
        'revenue': 3080.0,
        'imageUrl':
            'https://images.puma.com/image/upload/f_auto,q_auto,b_rgb:fafafa,w_2000,h_2000/global/369579/01/sv01/fnd/PNA/fmt/png/RS-X-Reinvention-Men\'s-Sneakers',
      },
      {
        'id': '4',
        'name': 'New Balance 990',
        'sales': 25,
        'revenue': 4375.0,
        'imageUrl':
            'https://nb.scene7.com/is/image/NB/m990gl5_nb_02_i?pdpflexf2&wid=440&hei=440',
      },
      {
        'id': '5',
        'name': 'Reebok Classic',
        'sales': 22,
        'revenue': 1760.0,
        'imageUrl':
            'https://assets.reebok.com/images/w_600,f_auto,q_auto/7acf66da3e67453aa6fcac700057ba2f_9366/Classic_Leather_Shoes_White_49799_01_standard.jpg',
      }
    ];
  }

  List<Map<String, dynamic>> _getMockCustomerAcquisition() {
    return [
      {'month': 'Jan', 'customers': 32},
      {'month': 'Feb', 'customers': 45},
      {'month': 'Mar', 'customers': 38},
      {'month': 'Apr', 'customers': 52},
      {'month': 'May', 'customers': 48},
      {'month': 'Jun', 'customers': 67}
    ];
  }

  Map<String, dynamic> _getMockOrderStatusDistribution() {
    return {'Processing': 28, 'Shipped': 35, 'Delivered': 30, 'Cancelled': 7};
  }

  List<Product> _getMockLowInventoryProducts() {
    return [
      Product(
        id: '4',
        name: 'New Balance 990',
        description: 'Premium quality running shoes',
        price: 175.00,
        imageUrl:
            'https://nb.scene7.com/is/image/NB/m990gl5_nb_02_i?pdpflexf2&wid=440&hei=440',
        discount: 0,
        category: 'Running',
        sizes: [8.0, 9.0, 10.0, 11.0],
        colors: ['Grey', 'Navy'],
        inStock: true,
        stockQuantity: 2,
      ),
      Product(
        id: '5',
        name: 'Reebok Classic',
        description: 'Iconic design with premium leather',
        price: 80.00,
        imageUrl:
            'https://assets.reebok.com/images/w_600,f_auto,q_auto/7acf66da3e67453aa6fcac700057ba2f_9366/Classic_Leather_Shoes_White_49799_01_standard.jpg',
        discount: 0,
        category: 'Casual',
        sizes: [7.0, 8.0, 9.0, 10.0, 11.0, 12.0],
        colors: ['White', 'Black', 'Grey'],
        inStock: true,
        stockQuantity: 3,
      ),
      Product(
        id: '7',
        name: 'Vans Old Skool',
        description: 'Classic skate shoes',
        price: 65.00,
        imageUrl:
            'https://images.vans.com/is/image/VansBrand/VN000D3HY28-HERO?583x583',
        discount: 0,
        category: 'Skateboarding',
        sizes: [8.0, 9.0, 10.0],
        colors: ['Black', 'White'],
        inStock: true,
        stockQuantity: 4,
      )
    ];
  }
}
