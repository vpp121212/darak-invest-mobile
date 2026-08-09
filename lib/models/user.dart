class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final String package;
  final DateTime? packageExpiry;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    this.package = 'basic',
    this.packageExpiry,
    this.createdAt,
  });

  bool get isPro => package == 'pro' || package == 'enterprise';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      package: json['package']?.toString() ?? 'basic',
      packageExpiry: json['packageExpiry'] != null
          ? DateTime.tryParse(json['packageExpiry'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'package': package,
      if (packageExpiry != null) 'packageExpiry': packageExpiry!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
