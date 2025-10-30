import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../services/reservation_api.dart';

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationApi _api;

  ReservationRepositoryImpl(this._api);

  @override
  Future<Reservation> createReservation({
    required String spaceId,
    required String slotStart,
    required String slotEnd,
    required int guestCount,
  }) async {
    try {
      final response = await _api.createReservation(
        spaceId: spaceId,
        slotStart: slotStart,
        slotEnd: slotEnd,
        guestCount: guestCount,
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
  Future<void> cancelReservation(String reservationId) async {
    try {
      await _api.cancelReservation(reservationId);
    } catch (e) {
      throw Exception('Error al cancelar la reserva: $e');
    }
  }

  @override
  Future<void> checkoutReservation(String reservationId) async {
    try {
      await _api.checkoutReservation(reservationId);
    } catch (e) {
      throw Exception('Error al hacer checkout: $e');
    }
  }

  @override
  Future<List<Reservation>> getClosedReservations() async {
    try {
      final response = await _api.getClosedReservations();
      return response.map((json) => Reservation.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener reservas cerradas: $e');
    }
  }
}
