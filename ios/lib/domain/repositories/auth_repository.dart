import '../entities/user.dart';

abstract class AuthRepository {
  /// Inicia sesión y devuelve el usuario autenticado
  Future<User> login(String email, String password);

  /// Token JWT actual
  String? get token;

  /// Usuario actual en memoria
  User? get currentUser;

  /// Cerrar sesión y limpiar datos
  Future<void> logout();

  /// Verifica si hay un usuario guardado en caché
  Future<bool> isUserLoggedIn();

  /// Verifica conectividad real
  Future<bool> hasInternetConnection();

  /// Determina si se puede iniciar sesión offline
  Future<bool> canAutoLogin();

  /// Registra un nuevo usuario
  Future<void> register({
    required String email,
    required String password,
    required String role, 
    String? name,
  });
}
