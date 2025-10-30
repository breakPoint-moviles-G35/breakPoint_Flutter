abstract class AuthRepository {
  Future<void> login(String email, String password);
  String? get token;
  Map<String, dynamic>? get currentUser;
  Future<void> logout();
  
  /// Verifica si hay un usuario guardado en SharedPreferences
  Future<bool> isUserLoggedIn();
  
  /// Verifica si el dispositivo tiene conexión a internet
  Future<bool> hasInternetConnection();
  
  /// Verifica si se puede permitir el login automático basado en conectividad
  Future<bool> canAutoLogin();
  
  Future<void> register({
    required String email,
    required String password,
    required String role, // "Student" | "Host"
    String? name,
  });
}
