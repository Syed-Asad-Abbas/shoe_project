import 'package:flutter/foundation.dart';

enum UserRole { customer, admin }

class User {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? address;
  final bool isAdmin;
  final DateTime? registrationDate;
  final DateTime? lastLogin;
  final int orderCount;
  final UserRole? role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.address,
    required this.isAdmin,
    this.registrationDate,
    this.lastLogin,
    this.orderCount = 0,
    this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      isAdmin: map['isAdmin'] ?? false,
      registrationDate: map['registrationDate'] != null
          ? DateTime.tryParse(map['registrationDate'])
          : null,
      lastLogin:
          map['lastLogin'] != null ? DateTime.tryParse(map['lastLogin']) : null,
      orderCount: map['orderCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'isAdmin': isAdmin,
      'registrationDate': registrationDate?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'orderCount': orderCount,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    bool? isAdmin,
    DateTime? registrationDate,
    DateTime? lastLogin,
    int? orderCount,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      isAdmin: isAdmin ?? this.isAdmin,
      registrationDate: registrationDate ?? this.registrationDate,
      lastLogin: lastLogin ?? this.lastLogin,
      orderCount: orderCount ?? this.orderCount,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, isAdmin: $isAdmin)';
  }
}
