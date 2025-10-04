import '../../domain/entities/reservation.dart';

abstract class ReservationRepository {
  Future<Reservation> createReservation({
    required String spaceId,
    required String startTime,
    required int durationHours,
    required int numberOfGuests,
    String? notes,
  });

  Future<List<Reservation>> getUserReservations();
  
  Future<Reservation> getReservationById(String reservationId);
  
  Future<void> cancelReservation(String reservationId);
  
  Future<bool> checkAvailability({
    required String spaceId,
    required String startTime,
    required int durationHours,
  });
}
