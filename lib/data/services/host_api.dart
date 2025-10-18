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
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener todos los perfiles de host (incluye user, spaces, spaces.reviews)
  Future<List<Map<String, dynamic>>> getAllHostProfiles() async {
    try {
      final res = await dio.get('/host-profile');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener el perfil del usuario autenticado
  Future<Map<String, dynamic>> getMyHostProfile() async {
    try {
      final res = await dio.get('/host-profile/my-profile');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener un perfil de host por ID
  Future<Map<String, dynamic>> getHostProfileById(String id) async {
    try {
      final res = await dio.get('/host-profile/$id');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    var msg = 'Error de red';
    
    // Manejo específico para timeouts
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'El servidor está tardando demasiado en responder. Verifica tu conexión o intenta más tarde.';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Error de conexión. Verifica que el servidor esté funcionando.';
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
