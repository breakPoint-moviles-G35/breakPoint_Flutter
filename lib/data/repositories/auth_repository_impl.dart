import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'dart:io';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../services/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;
  String? _token;
  User? _user;

  AuthRepositoryImpl(this.api);

  @override
  String? get token => _token;

  @override
  User? get currentUser => _user;

  /// 🔹 Carga el token y usuario desde cache local
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final jsonStr = prefs.getString('auth_user');
    if (jsonStr != null) {
      _user = User.fromJson(jsonDecode(jsonStr));
    }
  }

  @override
  Future<User> login(String email, String password) async {
    final res = await api.login(email: email, password: password);

    _token = res['access_token'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;

    if (_token == null || userData == null) {
      throw Exception('Respuesta inválida del servidor');
    }

    _user = User.fromJson(userData, token: _token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_user', jsonEncode(_user!.toJson()));

    return _user!;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String role,
    String? name,
  }) async {
    await api.register(email: email, password: password, role: role, name: name);
  }

  @override
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  @override
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('auth_user');
    return user != null;
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return false;

      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canAutoLogin() async {
    final hasUser = await isUserLoggedIn();
    final hasInternet = await hasInternetConnection();
    return hasUser && !hasInternet;
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    await api.changePassword(userId: userId, newPassword: newPassword);
  }
}
