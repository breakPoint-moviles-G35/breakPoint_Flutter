import 'package:dio/dio.dart';

class HostApi {
  final Dio dio;
  HostApi(this.dio);

  /// Crear un nuevo perfil de host
  Future<Map<String, dynamic>> createHostProfile({
    required String verificationStatus,
    required String payoutMethod,
    required String userId,
  }) async {
    try {
      final res = await dio.post('/host-profile', data: {
        'verification_status': verificationStatus,
        'payout_method': payoutMethod,
        'user_id': userId,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Obtener todos los perfiles de host (incluye user, spaces, reviews)
  Future<List<Map<String, dynamic>>> getAllHostProfiles() async {
    try {
      final res = await dio.get('/host-profile');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Obtener un perfil de host por su ID
  Future<Map<String, dynamic>> getHostProfileById(String id) async {
    try {
      final res = await dio.get('/host-profile/$id');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Obtener un perfil de host a partir del ID del usuario
  Future<Map<String, dynamic>> getHostProfileByUser(String userId) async {
    try {
      final res = await dio.get('/host-profile/by-user/$userId');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Obtener el perfil del host autenticado (si aplica autenticación con token)
  Future<Map<String, dynamic>> getMyHostProfile() async {
    try {
      final res = await dio.get('/host-profile/my-profile');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  /// Manejo centralizado de errores
  String _handleError(DioException e) {
    String msg = 'Error de red';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'No se pudo conectar al servidor. Verifica tu conexión.';
      case DioExceptionType.receiveTimeout:
        return 'El servidor está tardando demasiado en responder.';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica que el servidor esté activo.';
      default:
        break;
    }

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
