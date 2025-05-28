import 'package:flutter/foundation.dart';
import 'cart_item.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String email;
  final String phone;
  final List<CartItem> items;
  final double totalAmount;
  final double shippingCost;
  final OrderStatus status;
  final DateTime date;
  final String shippingAddress;
  final String paymentMethod;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.items,
    required this.totalAmount,
    this.shippingCost = 0.0,
    required this.status,
    required this.date,
    required this.shippingAddress,
    required this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: json['totalAmount'].toDouble(),
      shippingCost: (json['shippingCost'] ?? 0.0).toDouble(),
      status: _parseStatus(json['status']),
      date: DateTime.parse(json['date']),
      shippingAddress: json['shippingAddress'],
      paymentMethod: json['paymentMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'email': email,
      'phone': phone,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'shippingCost': shippingCost,
      'status': status.index,
      'date': date.toIso8601String(),
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
    };
  }

  static OrderStatus _parseStatus(dynamic status) {
    if (status is int && status >= 0 && status < OrderStatus.values.length) {
      return OrderStatus.values[status];
    } else if (status is String) {
      try {
        return OrderStatus.values.firstWhere(
            (s) => s.toString().toLowerCase().contains(status.toLowerCase()));
      } catch (_) {}
    }
    return OrderStatus.pending;
  }
}
