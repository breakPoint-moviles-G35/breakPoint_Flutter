import 'package:flutter/material.dart';
import '../../../domain/repositories/reservation_repository.dart';
import '../../../domain/entities/reservation.dart';

class ReservationViewModel extends ChangeNotifier {
  final ReservationRepository _repository;
  final double pricePerHour;
  final String spaceId;
  final String spaceAddress = '123 Business District, Suite 456, City Center';
  final double spaceRating = 4.8;
  final int reviewCount = 127;

  String? selectedTime;
  int durationHours = 1;
  int numberOfGuests = 1;
  String? notes;
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String? errorMessage;
  bool isCheckingAvailability = false;

  final List<String> availableTimes = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
  ];

  ReservationViewModel(this._repository, this.pricePerHour, this.spaceId) {
    selectedTime = availableTimes.first;
  }

  String get durationText => durationHours == 1 ? '1 hour' : '$durationHours hours';
  String get guestsText => numberOfGuests == 1 ? '1 guest' : '$numberOfGuests guests';
  double get totalPrice => pricePerHour * durationHours;

  bool get canDecreaseDuration => durationHours > 1;
  bool get canIncreaseDuration => durationHours < 8;
  bool get canDecreaseGuests => numberOfGuests > 1;
  bool get canIncreaseGuests => numberOfGuests < 20;
  bool get canReserve => selectedTime != null && !isLoading;

  void selectTime(String time) {
    selectedTime = time;
    notifyListeners();
  }

  void increaseDuration() {
    if (canIncreaseDuration) {
      durationHours++;
      notifyListeners();
    }
  }

  void decreaseDuration() {
    if (canDecreaseDuration) {
      durationHours--;
      notifyListeners();
    }
  }

  void increaseGuests() {
    if (canIncreaseGuests) {
      numberOfGuests++;
      notifyListeners();
    }
  }

  void decreaseGuests() {
    if (canDecreaseGuests) {
      numberOfGuests--;
      notifyListeners();
    }
  }

  void setNotes(String? newNotes) {
    notes = newNotes;
    notifyListeners();
  }

  String _parseTimeToISO(String timeString) {
    final timeParts = timeString.split(' ');
    final time = timeParts[0].split(':');
    final period = timeParts[1];

    int hour = int.parse(time[0]);
    final minute = int.parse(time[1]);

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    final dateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
    return dateTime.toIso8601String();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      selectedDate = picked;
      notifyListeners();
    }
  }

  Future<Reservation?> processReservation() async {
    if (!canReserve) return null;

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final start = _parseTimeToISO(selectedTime!);
      final end = DateTime.parse(start).add(Duration(hours: durationHours));

      final reservation = await _repository.createReservation(
        spaceId: spaceId,
        slotStart: start,
        slotEnd: end.toIso8601String(),
        guestCount: numberOfGuests,
      );

      return reservation;
    } catch (e) {
      errorMessage = 'Error al crear la reserva: $e';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
