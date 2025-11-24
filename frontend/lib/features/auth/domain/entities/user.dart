class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? accessToken;
  final String? refreshToken;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.accessToken,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] ?? json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}
