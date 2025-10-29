import 'package:dio/dio.dart';

class ReservationApi {
  final Dio dio;
  ReservationApi(this.dio);

  /// Crear una nueva reserva
  Future<Map<String, dynamic>> createReservation({
    required String spaceId,
    required String slotStart,
    required String slotEnd,
    required int guestCount,
  }) async {
    try {
      final res = await dio.post(
        '/booking',
        data: {
          'spaceId': spaceId,
          'slotStart': slotStart,
          'slotEnd': slotEnd,
          'guestCount': guestCount,
        },
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener reservas del usuario actual
  Future<List<Map<String, dynamic>>> getUserReservations() async {
    try {
      final res = await dio.get('/booking');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Obtener reservas activas ahora
  Future<List<Map<String, dynamic>>> getActiveNow() async {
    try {
      final res = await dio.get('/booking/active-now');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Hacer checkout de una reserva
  Future<void> checkoutReservation(String reservationId) async {
    try {
      await dio.post('/booking/$reservationId/checkout');
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  /// Cancelar una reserva
  Future<void> cancelReservation(String reservationId) async {
    try {
      await dio.delete('/booking/$reservationId');
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
