import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/reservation_repository.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/reservation.dart';

/// 🔹 ViewModel para RateScreen con gestión de almacenamiento local
/// ESTRATEGIA DE ALMACENAMIENTO LOCAL: SharedPreferences
/// - Guarda las reservas cerradas sin review en cache local
/// - Permite funcionar offline con datos guardados
class RateViewModel extends ChangeNotifier {
  final ReservationRepository reservationRepo;
  final ReviewRepository reviewRepo;
  final AuthRepository authRepo;

  bool isLoading = false;
  bool isOffline = false;
  String? error;
  List<Reservation> closed = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  RateViewModel({
    required this.reservationRepo,
    required this.reviewRepo,
    required this.authRepo,
  });

  /// Inicializa el ViewModel y configura la escucha de conectividad
  Future<void> init() async {
    final status = await Connectivity().checkConnectivity();
    isOffline = status.contains(ConnectivityResult.none);
    notifyListeners();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasNet = !result.contains(ConnectivityResult.none);
      if (hasNet && isOffline) {
        isOffline = false;
        load();
      } else if (!hasNet) {
        isOffline = true;
        notifyListeners();
      }
    });

    await load();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Carga las reservas cerradas sin review
  /// ESTRATEGIA: Si no hay internet, carga desde cache local (SharedPreferences)
  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final currentUser = authRepo.currentUser;
      if (currentUser == null) {
        error = 'Usuario no autenticado';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Verificar conectividad
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = !connectivity.contains(ConnectivityResult.none);
      isOffline = !hasInternet;
      notifyListeners();

      if (!hasInternet) {
        // 🔹 Sin internet: cargar desde cache local
        final cached = await _loadFromCache();
        if (cached.isNotEmpty) {
          closed = cached;
          error = null;
        } else {
          error = 'Sin conexión y sin datos guardados.';
        }
        isLoading = false;
        notifyListeners();
        return;
      }

      // Con internet: obtener del backend
      final allClosed = await reservationRepo.getClosedReservations();

      // Filtrar solo las que NO tienen review del usuario actual
      final closedWithoutReview = <Reservation>[];
      
      for (final reservation in allClosed) {
        try {
          final reviews = await reviewRepo.getReviewsBySpace(reservation.spaceId);
          final hasUserReview = reviews.any((review) => review.userId == currentUser.id);
          
          if (!hasUserReview) {
            closedWithoutReview.add(reservation);
          }
        } catch (e) {
          // Si hay error, asumir que no tiene review y agregar
          closedWithoutReview.add(reservation);
        }
      }

      // 🔹 Guardar en cache local (SharedPreferences)
      await _saveToCache(closedWithoutReview);

      closed = closedWithoutReview;
      error = null;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      // Intentar cargar desde cache si hubo error
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        closed = cached;
        error = null;
        isOffline = true;
      } else {
        error = 'Error al cargar reservas cerradas: $e';
        isOffline = true;
      }
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 ESTRATEGIA DE ALMACENAMIENTO LOCAL: Guarda en SharedPreferences
  /// Clave: 'cached_rate_reservations'
  /// Formato: JSON array de reservas
  Future<void> _saveToCache(List<Reservation> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((r) => r.toJson()).toList();
      await prefs.setString('cached_rate_reservations', jsonEncode(list));
      await prefs.setInt(
        'cached_rate_reservations_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Ignorar errores de cache
    }
  }

  /// 🔹 ESTRATEGIA DE ALMACENAMIENTO LOCAL: Carga desde SharedPreferences
  /// Lee la clave 'cached_rate_reservations' y deserializa las reservas
  Future<List<Reservation>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_rate_reservations');
      if (jsonStr == null || jsonStr.isEmpty) return [];

      final list = jsonDecode(jsonStr) as List;
      return list.map((json) => Reservation.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Reintenta cargar datos
  Future<void> retry() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasNetwork = !connectivity.contains(ConnectivityResult.none);
    isOffline = !hasNetwork;
    if (hasNetwork) {
      await load();
    } else {
      final cached = await _loadFromCache();
      closed = cached;
      notifyListeners();
    }
  }
}

