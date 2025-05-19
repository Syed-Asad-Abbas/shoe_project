import 'package:flutter/foundation.dart';
import 'product.dart';

enum OrderStatus { processing, shipped, delivered, cancelled }

class OrderItem {
  final Product product;
  final int quantity;
  final String size;
  final String? color;

  OrderItem({
    required this.product,
    required this.quantity,
    required this.size,
    this.color,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle the case where the API sends a simpler structure for order items
    if (json['product'] == null && json['productId'] != null) {
      // Create a minimal product from the available data
      final productData = {
        'id': json['productId'],
        '_id': json['productId'],
        'name': json['name'] ?? 'Unknown Product',
        'price': json['price'] ?? 0.0,
        'imageUrl': json['imageUrl'] ?? '',
        'description': '',
        'category': '',
      };

      return OrderItem(
        product: Product.fromJson(productData),
        quantity: json['quantity'] ?? 1,
        size: json['size'] ?? '',
        color: json['color'],
      );
    }

    // Standard case with full product object
    return OrderItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      size: json['size'] ?? '',
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'size': size,
      'color': color,
    };
  }
}

class Order {
  final String id;
  final String customerName;
  final String customerEmail;
  final DateTime orderDate;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double total;
  final String shippingAddress;
  final String paymentMethod;
  final String? trackingNumber;
  final DateTime? deliveryDate;

  Order({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.orderDate,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.tax,
    required this.total,
    required this.shippingAddress,
    required this.paymentMethod,
    this.trackingNumber,
    this.deliveryDate,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      status: _parseStatus(json['status']),
      items: json['items'] != null
          ? List<OrderItem>.from(
              json['items'].map((item) => OrderItem.fromJson(item)))
          : [],
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      shippingCost: (json['shippingCost'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
      total: (json['totalAmount'] ?? json['total'] ?? 0.0).toDouble(),
      shippingAddress: json['shippingAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      trackingNumber: json['trackingNumber'],
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'orderDate': orderDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'tax': tax,
      'total': total,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'deliveryDate': deliveryDate?.toIso8601String(),
    };
  }

  static OrderStatus _parseStatus(dynamic status) {
    // Handle integer status codes from API
    if (status is int) {
      switch (status) {
        case 0:
          return OrderStatus.processing;
        case 1:
          return OrderStatus.processing;
        case 2:
          return OrderStatus.shipped;
        case 3:
          return OrderStatus.delivered;
        case 4:
          return OrderStatus.cancelled;
        default:
          return OrderStatus.processing;
      }
    }

    // Handle string status
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'processing':
          return OrderStatus.processing;
        case 'shipped':
          return OrderStatus.shipped;
        case 'delivered':
          return OrderStatus.delivered;
        case 'cancelled':
          return OrderStatus.cancelled;
        default:
          return OrderStatus.processing;
      }
    }

    // Default fallback
    return OrderStatus.processing;
  }

  // Convenience method to convert OrderStatus to string for display
  String get statusText => status.toString().split('.').last;
}
