// presentation/login/viewmodel/auth_viewmodel.dart
import 'package:flutter/material.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/user.dart'; // asegúrate de tener tu entidad User

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;
  AuthViewModel(this.repo);

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  User? _currentUser; // Usuario autenticado en memoria

  User? get currentUser => _currentUser;

  /// Retorna el rol actual del usuario ("Host" o "Student")
  String? get userRole => _currentUser?.role;

  /// Inicia sesión con email y contraseña
  Future<bool> login() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final user = await repo.login(emailCtrl.text.trim(), passCtrl.text);
      _currentUser = user; // guardar usuario retornado por el repo
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un usuario y (opcional) hace login automático
  Future<bool> register({
    required String email,
    required String password,
    required String role, // "Student" | "Host"
    String? name,
    bool autoLogin = true,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await repo.register(
        email: email.trim(),
        password: password,
        role: role,
        name: name,
      );

      if (autoLogin) {
        final user = await repo.login(email.trim(), password);
        _currentUser = user;
      }

      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia errores y estado
  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    await repo.logout();
    _currentUser = null;
    emailCtrl.clear();
    passCtrl.clear();
    notifyListeners();
  }
}
