// presentation/login/viewmodel/auth_viewmodel.dart
import 'package:flutter/material.dart';
import '../../../domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;
  AuthViewModel(this.repo);

  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await repo.login(emailCtrl.text.trim(), passCtrl.text);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Registra un usuario y (opcional) hace login automático.
  Future<bool> register({
    required String email,
    required String password,
    required String role,     // "Student" | "Host"
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
        await repo.login(email.trim(), password);
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

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }
}
