import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<Reservation> createReservation({
    required String spaceId,
    required String slotStart,
    required String slotEnd,
    required int guestCount,
  });

  Future<List<Reservation>> getUserReservations();

  Future<List<Reservation>> hasUpcomingReservations();

  Future<void> cancelReservation(String reservationId);

  /// Realiza checkout de una reserva
  Future<void> checkoutReservation(String reservationId);

  /// Listado de reservas cerradas del usuario actual
  Future<List<Reservation>> getClosedReservations();
}
