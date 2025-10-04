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

  // Estados de la reserva
  String? selectedTime;
  int durationHours = 1;
  int numberOfGuests = 1;
  String? notes;

  // Estados de la UI
  bool isLoading = false;
  String? errorMessage;
  bool isCheckingAvailability = false;

  // Horarios disponibles
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
    // Seleccionar la primera hora disponible por defecto
    selectedTime = availableTimes.first;
  }

  // Getters para el texto de la UI
  String get durationText {
    if (durationHours == 1) {
      return '1 hour';
    }
    return '$durationHours hours';
  }

  String get guestsText {
    if (numberOfGuests == 1) {
      return '1 guest';
    }
    return '$numberOfGuests guests';
  }

  double get totalPrice => pricePerHour * durationHours;

  // Validaciones
  bool get canDecreaseDuration => durationHours > 1;
  bool get canIncreaseDuration => durationHours < 8; // Máximo 8 horas
  bool get canDecreaseGuests => numberOfGuests > 1;
  bool get canIncreaseGuests => numberOfGuests < 20; // Máximo 20 invitados
  bool get canReserve => selectedTime != null && !isLoading;

  // Métodos para cambiar el estado
  void selectTime(String time) {
    selectedTime = time;
    _checkAvailability();
    notifyListeners();
  }

  void increaseDuration() {
    if (canIncreaseDuration) {
      durationHours++;
      _checkAvailability();
      notifyListeners();
    }
  }

  void decreaseDuration() {
    if (canDecreaseDuration) {
      durationHours--;
      _checkAvailability();
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

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  // Verificar disponibilidad cuando cambian los parámetros
  Future<void> _checkAvailability() async {
    if (selectedTime == null) return;

    try {
      isCheckingAvailability = true;
      notifyListeners();

      final startTime = _parseTimeToISO(selectedTime!);
      final isAvailable = await _repository.checkAvailability(
        spaceId: spaceId,
        startTime: startTime,
        durationHours: durationHours,
      );

      if (!isAvailable) {
        errorMessage = 'Este horario no está disponible';
      } else {
        errorMessage = null;
      }
    } catch (e) {
      errorMessage = 'Error al verificar disponibilidad: $e';
    } finally {
      isCheckingAvailability = false;
      notifyListeners();
    }
  }

  // Convertir tiempo seleccionado a ISO string
  String _parseTimeToISO(String timeString) {
    final now = DateTime.now();
    final timeParts = timeString.split(' ');
    final time = timeParts[0].split(':');
    final period = timeParts[1];

    int hour = int.parse(time[0]);
    final minute = int.parse(time[1]);

    // Convertir a formato 24 horas
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    final dateTime = DateTime(now.year, now.month, now.day, hour, minute);
    return dateTime.toIso8601String();
  }

  // Método para procesar la reserva
  Future<Reservation?> processReservation() async {
    if (!canReserve) return null;

    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final startTime = _parseTimeToISO(selectedTime!);
      
      final reservation = await _repository.createReservation(
        spaceId: spaceId,
        startTime: startTime,
        durationHours: durationHours,
        numberOfGuests: numberOfGuests,
        notes: notes,
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
