import 'package:flutter/material.dart';
import '../../../domain/repositories/reservation_repository.dart';
import '../../../domain/entities/reservation.dart';

class ReservationViewModel extends ChangeNotifier {
  final ReservationRepository _repository;
  final double pricePerHour;
  final String spaceId;

  String? selectedTime;
  int durationHours = 1;
  int numberOfGuests = 1;
  String? notes;
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String? errorMessage;
  bool isCheckingAvailability = false;

  final List<String> availableTimes = [
    '7:00 AM','8:00 AM','9:00 AM','10:00 AM','11:00 AM','12:00 PM',
    '1:00 PM','2:00 PM','3:00 PM','4:00 PM','5:00 PM','6:00 PM','7:00 PM','8:00 PM','9:00 PM',
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
    
    // Crear DateTime en hora local explícitamente
    final dateTimeLocal = DateTime(
      selectedDate.year, 
      selectedDate.month, 
      selectedDate.day, 
      hour, 
      minute
    );
    
    // Convertir a UTC antes de enviar al backend
    // Asegurarnos de que la conversión sea correcta
    final dateTimeUtc = dateTimeLocal.toUtc();
    return dateTimeUtc.toIso8601String();
  }
  
  /// Valida que la hora seleccionada no haya pasado
  /// Permite reservas con al menos 1 hora de anticipación
  bool _isTimeInPast(DateTime dateTime) {
    // Asegurarse de usar hora local
    final now = DateTime.now(); // DateTime.now() ya devuelve hora local
    // Agregar 1 hora de margen para evitar problemas de zona horaria
    final minimumTime = now.add(const Duration(hours: 1));
    
    // Comparar solo fecha y hora, ignorando segundos y milisegundos
    // Asegurarse de que ambos DateTime estén en hora local
    final selected = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
    );
    final minimum = DateTime(
      minimumTime.year,
      minimumTime.month,
      minimumTime.day,
      minimumTime.hour,
      minimumTime.minute,
    );
    return selected.isBefore(minimum);
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

      // Primero validar en hora local antes de convertir
      final timeParts = selectedTime!.split(' ');
      final time = timeParts[0].split(':');
      final period = timeParts[1];
      int hour = int.parse(time[0]);
      final minute = int.parse(time[1]);
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      
      final dateTimeLocal = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        minute,
      );
      
      // Validar que la hora no haya pasado (con margen de 1 hora)
      if (_isTimeInPast(dateTimeLocal)) {
        final now = DateTime.now(); // Esto ya está en hora local
        final minHour = now.add(const Duration(hours: 1));
        // Formatear la hora en formato 12 horas (AM/PM) - asegurarse de usar hora local
        final hour12 = minHour.hour > 12 ? minHour.hour - 12 : (minHour.hour == 0 ? 12 : minHour.hour);
        final period = minHour.hour >= 12 ? 'PM' : 'AM';
        errorMessage = 'La hora de inicio debe ser al menos 1 hora en el futuro. Hora mínima: $hour12:${minHour.minute.toString().padLeft(2, '0')} $period';
        return null;
      }

      // Convertir a UTC para enviar al backend
      final start = dateTimeLocal.toUtc().toIso8601String();
      final startUtc = DateTime.parse(start);
      final endUtc = startUtc.add(Duration(hours: durationHours));

      final reservation = await _repository.createReservation(
        spaceId: spaceId,
        slotStart: start,
        slotEnd: endUtc.toIso8601String(),
        guestCount: numberOfGuests,
      );

      // TODO: podríamos cachear/emitir evento para listado.
      return reservation;
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('not available') || msg.toLowerCase().contains('overlap')) {
        errorMessage = 'El horario seleccionado ya está reservado. Prueba otra hora.';
      } else if (msg.toLowerCase().contains('hora de inicio') || msg.toLowerCase().contains('start time')) {
        errorMessage = 'La hora de inicio seleccionada ya ha pasado. Por favor selecciona una hora futura.';
      } else {
        errorMessage = 'Error al crear la reserva: $e';
      }
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
