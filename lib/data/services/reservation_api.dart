import 'package:dio/dio.dart';

class ReservationApi {
  final Dio dio;
  ReservationApi(this.dio);

  /// Crear una nueva reserva
  Future<Map<String, dynamic>> createReservation({
    required String spaceId,
    required String startTime, // ISO string
    required int durationHours,
    required int numberOfGuests,
    String? notes,
  }) async {
    try {
      final res = await dio.post('/reservations', data: {
        'spaceId': spaceId,
        'startTime': startTime,
        'durationHours': durationHours,
        'numberOfGuests': numberOfGuests,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener reservas del usuario actual
  Future<List<Map<String, dynamic>>> getUserReservations() async {
    try {
      final res = await dio.get('/reservations/user');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener una reserva específica por ID
  Future<Map<String, dynamic>> getReservationById(String reservationId) async {
    try {
      final res = await dio.get('/reservations/$reservationId');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Cancelar una reserva
  Future<void> cancelReservation(String reservationId) async {
    try {
      await dio.delete('/reservations/$reservationId');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Verificar disponibilidad de un espacio en un horario específico
  Future<bool> checkAvailability({
    required String spaceId,
    required String startTime,
    required int durationHours,
  }) async {
    try {
      final res = await dio.get('/reservations/availability', queryParameters: {
        'spaceId': spaceId,
        'startTime': startTime,
        'durationHours': durationHours,
      });
      return res.data['available'] as bool;
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
