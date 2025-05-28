import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final String size;
  int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.product,
    required this.size,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.id,
      'size': size,
      'quantity': quantity,
      'price': price,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json, {Product? productData}) {
    return CartItem(
      id: json['id'] ?? '',
      product: productData ?? Product.fromJson(json['product']),
      size: json['size'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? size,
    double? price,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
} 