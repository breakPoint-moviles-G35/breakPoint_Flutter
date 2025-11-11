// lib/domain/entities/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String role; 
  final String? status;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status,
    this.token,
  });

  /// Constructor desde JSON (como el backend NestJS)
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'Student',
      status: json['status'],
      token: token,
    );
  }

  /// Convierte el objeto a mapa (opcional)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'token': token,
    };
  }
}
