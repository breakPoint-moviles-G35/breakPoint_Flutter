import 'package:flutter/material.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/repositories/reservation_repository.dart';

class ReservationsStore extends ChangeNotifier {
  final List<Reservation> _items = [];

  List<Reservation> get items => List.unmodifiable(_items);

  void add(Reservation r) {
    _items.insert(0, r);
    notifyListeners();
  }

  Future<void> sync(ReservationRepository repo) async {
    try {
      final remote = await repo.getUserReservations();
      _items
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } catch (_) {
      // Mantener locales si falla
    }
  }
}


