// data/repositories/auth_repository_impl.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi api;
  String? _token;
  Map<String, dynamic>? _user;

  AuthRepositoryImpl(this.api);

  @override
  String? get token => _token;

  @override
  Map<String, dynamic>? get currentUser => _user;

  /// Carga el token y un user_id mínimo desde SharedPreferences al iniciar la app
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final uid = prefs.getString('user_id');
    if (uid != null && uid.isNotEmpty) {
      _user = {'id': uid};
    }
  }

  @override
  Future<void> login(String email, String password) async {
    final res = await api.login(email: email, password: password);
    _token = res['access_token'] as String?;
    _user  = res['user'] as Map<String, dynamic>?;

    if (_token == null) {
      throw Exception('Token ausente en login');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_id', (_user?['id'] as String? ?? ''));
    await prefs.setString('auth_user', (_user ?? {}).toString());
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String role,
    String? name,
  }) async {
    // No guarda token (eso se hace en login si autoLogin=true)
    await api.register(email: email, password: password, role: role, name: name);
  }

  @override
  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    await prefs.remove('user_id');
  }
}
