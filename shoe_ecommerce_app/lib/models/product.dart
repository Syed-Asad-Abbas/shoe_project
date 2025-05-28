import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String? brand;
  final List<double> sizes;
  final List<String> colors;
  final bool inStock;
  final int discount;
  final bool isFavorite;
  final double rating;
  final int reviewCount;
  final int stockQuantity;
  final bool featured;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.brand,
    required this.sizes,
    required this.colors,
    required this.inStock,
    this.discount = 0,
    this.isFavorite = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stockQuantity = 0,
    this.featured = false,
  });

  bool get hasLowStock => stockQuantity < 5;

  double get discountedPrice {
    if (discount == 0) return price;
    return price - (price * discount / 100);
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    String? brand,
    List<double>? sizes,
    List<String>? colors,
    bool? inStock,
    int? discount,
    bool? isFavorite,
    double? rating,
    int? reviewCount,
    int? stockQuantity,
    bool? featured,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      inStock: inStock ?? this.inStock,
      discount: discount ?? this.discount,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      featured: featured ?? this.featured,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'sizes': sizes,
      'colors': colors,
      'category': category,
      'brand': brand,
      'inStock': inStock,
      'discount': discount,
      'isFavorite': isFavorite,
      'rating': rating,
      'reviewCount': reviewCount,
      'stockQuantity': stockQuantity,
      'featured': featured,
    };
  }

  factory Product.fromJson(Map<String, dynamic> map) {
    return Product(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'],
      sizes: map['sizes'] != null
          ? List<double>.from(map['sizes'].map((size) => size is int
              ? size.toDouble()
              : size is String
                  ? double.tryParse(size) ?? 0.0
                  : size.toDouble()))
          : [],
      colors: map['colors'] != null ? List<String>.from(map['colors']) : [],
      inStock: map['inStock'] ?? true,
      discount: map['discount'] ?? 0,
      isFavorite: map['isFavorite'] ?? false,
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      stockQuantity: map['stockQuantity'] ?? 0,
      featured: map['featured'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category, stockQuantity: $stockQuantity)';
  }
}
