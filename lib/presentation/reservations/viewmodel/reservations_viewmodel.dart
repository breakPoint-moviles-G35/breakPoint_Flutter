import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/nfc_service.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/repositories/reservation_repository.dart';

class ReservationsViewModel extends ChangeNotifier {
  final ReservationRepository repo;
  final NfcService nfcService;
  bool _initialized = false;

  bool isLoading = false;
  bool isOffline = false;
  String? error;
  List<Reservation> reservations = [];
  bool isNfcListening = false;

  ReservationsViewModel(this.repo, this.nfcService);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final status = await Connectivity().checkConnectivity();
    isOffline = status.contains(ConnectivityResult.none);

    await load();

    Connectivity().onConnectivityChanged.listen((result) async {
      final hasNet = !result.contains(ConnectivityResult.none);
      if (hasNet && isOffline) {
        isOffline = false;
        await retry();
      } else if (!hasNet) {
        isOffline = true;
        notifyListeners();
      }
    });
  }

  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final status = await Connectivity().checkConnectivity();
      final hasNetwork = !status.contains(ConnectivityResult.none);
      isOffline = !hasNetwork;

      if (!hasNetwork) {
        final ok = await _loadFromCache();
        if (!ok) {
          error = 'Sin conexión y sin datos guardados.';
        }
        notifyListeners();
        return;
      }

      final all = await repo.getUserReservations();
      final now = DateTime.now();

      reservations = all
          .where((r) {
            final isUpcoming = r.slotStart.isAfter(now);
            final isOngoing =
                r.slotStart.isBefore(now) && r.slotEnd.isAfter(now);
            return r.status == ReservationStatus.confirmed &&
                (isUpcoming || isOngoing);
          })
          .toList()
        ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

      await _saveToCache(reservations);

      error = null;
      notifyListeners();
    } catch (e) {
      final ok = await _loadFromCache();
      if (!ok) {
        error = 'Error al cargar reservas: $e';
      }
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    final status = await Connectivity().checkConnectivity();
    final hasNetwork = !status.contains(ConnectivityResult.none);
    isOffline = !hasNetwork;
    if (hasNetwork) {
      await load();
    } else {
      await _loadFromCache();
      notifyListeners();
    }
  }

  Future<void> _saveToCache(List<Reservation> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((r) => r.toJson()).toList();
      await prefs.setString('cached_reservations', jsonEncode(list));
      await prefs.setInt(
        'cached_reservations_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<bool> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_reservations');
      if (jsonString == null || jsonString.isEmpty) {
        reservations = [];
        return false;
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      reservations = decoded
          .map((m) => Reservation.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return reservations.isNotEmpty;
    } catch (_) {
      reservations = [];
      return false;
    }
  }

  Future<String?> startNfcListening() async {
    try {
      isNfcListening = true;
      notifyListeners();

      final result = await nfcService.readNfcTag();

      isNfcListening = false;
      notifyListeners();

      if (result != null &&
          !result.startsWith('Error') &&
          !result.startsWith('NFC is not available')) {
        return result;
      }

      return null;
    } catch (_) {
      isNfcListening = false;
      notifyListeners();
      return null;
    }
  }

  Reservation? getMostProximalReservation() {
    if (reservations.isEmpty) return null;

    final now = DateTime.now();

    final sorted = List<Reservation>.from(reservations)
      ..sort((a, b) {
        final aDiff = a.slotStart.difference(now).abs();
        final bDiff = b.slotStart.difference(now).abs();
        return aDiff.compareTo(bDiff);
      });

    return sorted.first;
  }

  Future<bool> closeMostProximalReservation() async {
    try {
      final reservation = getMostProximalReservation();
      if (reservation == null) {
        error = 'No hay reservas para cerrar';
        notifyListeners();
        return false;
      }

      error = null;
      notifyListeners();

      await repo.checkoutReservation(reservation.id);

      await load();

      return true;
    } catch (e) {
      error = 'Error al cerrar la reserva: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
