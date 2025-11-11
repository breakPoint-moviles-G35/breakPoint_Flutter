import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/repositories/reservation_repository.dart';
import '../../../data/services/nfc_service.dart';

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

  // =====================================================
  // Inicialización y escucha de conectividad
  // =====================================================
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final status = await Connectivity().checkConnectivity();
    isOffline = status.contains(ConnectivityResult.none);

    await load();

    //Escucha cambios automáticos de red
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

  // ================= NFC =================
  Future<String?> startNfcListening() async {
    try {
      isNfcListening = true;
      notifyListeners();
      final result = await nfcService.readNfcTag();
      isNfcListening = false;
      notifyListeners();
      if (result != null && !result.startsWith('Error')) {
        return result;
      }
      return null;
    } catch (_) {
      isNfcListening = false;
      notifyListeners();
      return null;
    }
  }

  // =====================================================
  // Carga principal (online / offline)
  // =====================================================
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

      // 🔹 Con red: obtener reservas desde el backend
      final all = await repo.getUserReservations();
      final now = DateTime.now();

      reservations = all.where((r) {
        final isUpcoming = r.slotStart.isAfter(now);
        final isOngoing =
            r.slotStart.isBefore(now) && r.slotEnd.isAfter(now);
        return r.status == ReservationStatus.confirmed &&
            (isUpcoming || isOngoing);
      }).toList()
        ..sort((a, b) => a.slotStart.compareTo(b.slotStart));

      // Guardar caché
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

  // =====================================================
  // Reintentar manualmente (desde OfflineBanner)
  // =====================================================
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

  // =====================================================
  // Métodos de caché local
  // =====================================================
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
}
