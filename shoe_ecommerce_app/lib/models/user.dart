class User {
  final String id;
  final String name;
  final String email;
  final String? address;
  final String? phone;
  final List<String> favorites;
  final bool isAdmin;
  final String? firebaseUid;
  final String? photoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.address,
    this.phone,
    this.favorites = const [],
    this.isAdmin = false,
    this.firebaseUid,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      address: json['address'],
      phone: json['phone'],
      favorites:
          json['favorites'] != null ? List<String>.from(json['favorites']) : [],
      isAdmin: json['isAdmin'] ?? json['role'] == 'admin' ? true : false,
      firebaseUid: json['firebaseUid'],
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'address': address,
      'phone': phone,
      'favorites': favorites,
      'isAdmin': isAdmin,
      'firebaseUid': firebaseUid,
      'photoUrl': photoUrl,
    };
  }
}
