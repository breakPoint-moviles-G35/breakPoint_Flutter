import 'package:dio/dio.dart';

class SpaceApi {
  final Dio dio;
  SpaceApi(this.dio);

  /// Buscar espacios con filtros
  Future<List<Map<String, dynamic>>> searchSpaces({
    String? query,
    bool sortAsc = true,
    String? start,
    String? end,
  }) async {
    final qp = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
    };

    final res = await dio.get(
      sortAsc ? '/space/sorted' : '/space',
      queryParameters: qp,
    );

    return (res.data as List).cast<Map<String, dynamic>>();
  }

  /// Obtener un espacio por ID
  Future<Map<String, dynamic>> getSpaceById(String id) async {
    final res = await dio.get('/space/$id');
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Obtener el espacio más cercano
  Future<Map<String, dynamic>> getNearestSpace({
    required double latitude,
    required double longitude,
  }) async {
    final res = await dio.get(
      '/space/nearest',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Obtener recomendaciones personalizadas
  Future<List<Map<String, dynamic>>> getRecommendations(String userId) async {
    final res = await dio.get('/space/recommendations/$userId');
    return (res.data as List).cast<Map<String, dynamic>>();
  }


  /// Obtener todos los espacios creados por un host específico
  Future<List<Map<String, dynamic>>> getSpacesByHost(String hostProfileId) async {
    try {
      final res = await dio.get('/space/by-host/$hostProfileId');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Crear un nuevo espacio vinculado a un HostProfile
  Future<Map<String, dynamic>> createSpace(Map<String, dynamic> data) async {
    try {
      final res = await dio.post('/space', data: data);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    var msg = 'Error al comunicarse con el servidor';
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
