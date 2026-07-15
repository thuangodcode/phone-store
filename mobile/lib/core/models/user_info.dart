class UserInfo {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String avatar;
  final String address;

  UserInfo({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatar,
    required this.address,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      avatar: json['avatar'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'address': address,
    };
  }
}
