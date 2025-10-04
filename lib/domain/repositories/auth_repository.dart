abstract class AuthRepository {
  Future<void> login(String email, String password);
  String? get token;
  Map<String, dynamic>? get currentUser;
  Future<void> logout();

  
  Future<void> register({
    required String email,
    required String password,
    required String role, // "Student" | "Host"
    String? name,
  });
}
