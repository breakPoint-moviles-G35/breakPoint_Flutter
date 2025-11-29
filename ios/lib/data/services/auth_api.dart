// data/services/auth_api.dart
import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String role, // "Student" | "Host"
    String? name,
  }) async {
    try {
      await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'role': role,
        if (name != null && name.isNotEmpty) 'name': name,
      });
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    var msg = 'Error de red';
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is String) msg = m;
      if (m is List && m.isNotEmpty) msg = m.first.toString();
    } else if (e.message != null) {
      msg = e.message!;
    }
    return msg;
    }
}
