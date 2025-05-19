import 'package:flutter/foundation.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<double> sizes;
  final List<String> colors;
  final String category;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int discount;
  final int stockQuantity;
  final bool featured;
  final bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sizes,
    required this.colors,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.discount,
    required this.stockQuantity,
    required this.featured,
    this.isFavorite = false,
  });

  bool get hasLowStock => stockQuantity < 5;

  double get discountedPrice {
    if (discount > 0) {
      return price - (price * discount / 100);
    }
    return price;
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    List<double>? sizes,
    List<String>? colors,
    String? category,
    double? rating,
    int? reviewCount,
    bool? inStock,
    int? discount,
    int? stockQuantity,
    bool? featured,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
      discount: discount ?? this.discount,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      featured: featured ?? this.featured,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'rating': rating,
      'reviewCount': reviewCount,
      'inStock': inStock,
      'discount': discount,
      'stockQuantity': stockQuantity,
      'featured': featured,
      'isFavorite': isFavorite,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] is String)
          ? double.tryParse(json['price']) ?? 0.0
          : (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      sizes: _parseSizes(json['sizes']),
      colors: _parseColors(json['colors']),
      category: json['category'] ?? '',
      rating: (json['rating'] is String)
          ? double.tryParse(json['rating']) ?? 0.0
          : (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      inStock: json['inStock'] ?? true,
      discount: json['discount'] ?? 0,
      stockQuantity: json['stockQuantity'] ?? 0,
      featured: json['featured'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Helper method to parse sizes
  static List<double> _parseSizes(dynamic sizes) {
    if (sizes == null) return [];

    try {
      if (sizes is List) {
        return List<double>.from(sizes.map((size) {
          if (size is String) {
            return double.tryParse(size) ?? 0.0;
          } else {
            return size.toDouble();
          }
        }));
      } else if (sizes is String) {
        // Handle case where sizes might be a comma-separated string
        return sizes
            .split(',')
            .map((s) => double.tryParse(s.trim()) ?? 0.0)
            .toList();
      }
    } catch (e) {
      print('Error parsing sizes: $e');
    }

    return [];
  }

  // Helper method to parse colors
  static List<String> _parseColors(dynamic colors) {
    if (colors == null) return [];

    try {
      if (colors is List) {
        return List<String>.from(colors);
      } else if (colors is String) {
        // Handle case where colors might be a comma-separated string
        return colors.split(',').map((c) => c.trim()).toList();
      }
    } catch (e) {
      print('Error parsing colors: $e');
    }

    return [];
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category, stockQuantity: $stockQuantity)';
  }
}
