import '../entities/reservation.dart';

abstract class ReservationRepository {
  Future<Reservation> createReservation({
    required String spaceId,
    required String slotStart,
    required String slotEnd,
    required int guestCount,
  });

  Future<List<Reservation>> getUserReservations();

  Future<void> cancelReservation(String reservationId);
}
