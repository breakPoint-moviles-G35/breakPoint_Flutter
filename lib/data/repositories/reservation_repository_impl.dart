import 'package:dio/dio.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../services/reservation_api.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationApi _api;

  ReservationRepositoryImpl(this._api);

  @override
  Future<Reservation> createReservation({
    required String spaceId,
    required String startTime,
    required int durationHours,
    required int numberOfGuests,
    String? notes,
  }) async {
    try {
      final response = await _api.createReservation(
        spaceId: spaceId,
        startTime: startTime,
        durationHours: durationHours,
        numberOfGuests: numberOfGuests,
        notes: notes,
      );
      return Reservation.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear la reserva: $e');
    }
  }

  @override
  Future<List<Reservation>> getUserReservations() async {
    try {
      final response = await _api.getUserReservations();
      return response.map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las reservas: $e');
    }
  }

  @override
  Future<Reservation> getReservationById(String reservationId) async {
    try {
      final response = await _api.getReservationById(reservationId);
      return Reservation.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener la reserva: $e');
    }
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    try {
      await _api.cancelReservation(reservationId);
    } catch (e) {
      throw Exception('Error al cancelar la reserva: $e');
    }
  }

  @override
  Future<bool> checkAvailability({
    required String spaceId,
    required String startTime,
    required int durationHours,
  }) async {
    try {
      return await _api.checkAvailability(
        spaceId: spaceId,
        startTime: startTime,
        durationHours: durationHours,
      );
    } catch (e) {
      throw Exception('Error al verificar disponibilidad: $e');
    }
  }
}
