class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final DateTime joinDate;
  final String? address;
  final int orderCount;
  final double totalSpent;
  final bool isActive;
  final List<String>? favoriteProductIds;
  final String? lastOrderDate;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    required this.joinDate,
    this.address,
    required this.orderCount,
    required this.totalSpent,
    required this.isActive,
    this.favoriteProductIds,
    this.lastOrderDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      joinDate: json['joinDate'] != null
          ? DateTime.parse(json['joinDate'])
          : DateTime.now(),
      address: json['address'],
      orderCount: json['orderCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? true,
      favoriteProductIds: json['favoriteProductIds'] != null
          ? List<String>.from(json['favoriteProductIds'])
          : null,
      lastOrderDate: json['lastOrderDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'joinDate': joinDate.toIso8601String(),
      'address': address,
      'orderCount': orderCount,
      'totalSpent': totalSpent,
      'isActive': isActive,
      'favoriteProductIds': favoriteProductIds,
      'lastOrderDate': lastOrderDate,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    DateTime? joinDate,
    String? address,
    int? orderCount,
    double? totalSpent,
    bool? isActive,
    List<String>? favoriteProductIds,
    String? lastOrderDate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      joinDate: joinDate ?? this.joinDate,
      address: address ?? this.address,
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      isActive: isActive ?? this.isActive,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
    );
  }
}
