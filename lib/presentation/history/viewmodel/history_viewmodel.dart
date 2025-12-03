import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/reservation_repository.dart';
import '../../../domain/repositories/review_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/reservation.dart';

/// 🔹 ViewModel para HistoryScreen con gestión de almacenamiento local
/// ESTRATEGIA DE ALMACENAMIENTO LOCAL: SharedPreferences
/// - Guarda las reservas con review en cache local
/// - Permite funcionar offline con datos guardados
/// - Calcula estadísticas en isolate
class HistoryViewModel extends ChangeNotifier {
  final ReservationRepository reservationRepo;
  final ReviewRepository reviewRepo;
  final AuthRepository authRepo;

  bool isLoading = false;
  bool isOffline = false;
  String? error;
  List<Reservation> historyReservations = [];
  Map<String, dynamic>? stats; // Estadísticas calculadas en isolate
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  HistoryViewModel({
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

  /// Carga las reservas cerradas con review
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

      List<Reservation> fetchedReservations;

      if (!hasInternet) {
        // 🔹 Sin internet: cargar desde cache local
        final cached = await _loadFromCache();
        if (cached.isNotEmpty) {
          fetchedReservations = cached;
          error = null;
          // Calcular estadísticas desde cache
          await _calculateStats(fetchedReservations);
        } else {
          error = 'Sin conexión y sin datos guardados.';
          isLoading = false;
          notifyListeners();
          return;
        }
      } else {
        // Con internet: obtener del backend
        final closedReservations = await reservationRepo.getClosedReservations();

        // Filtrar las que tienen review del usuario actual
        final reservationsWithReview = <Reservation>[];

        for (final reservation in closedReservations) {
          try {
            final reviews = await reviewRepo.getReviewsBySpace(reservation.spaceId);
            final hasUserReview = reviews.any((review) => review.userId == currentUser.id);

            if (hasUserReview) {
              reservationsWithReview.add(reservation);
            }
          } catch (e) {
            // Ignorar esta reserva si hay error
          }
        }
        fetchedReservations = reservationsWithReview;

        // 🔹 Guardar en cache local (SharedPreferences)
        await _saveToCache(fetchedReservations);

        // 🔹 Calcular estadísticas en isolate
        await _calculateStats(fetchedReservations);
      }

      historyReservations = fetchedReservations;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      // Intentar cargar desde cache si hubo error
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        await _calculateStats(cached);
        historyReservations = cached;
        error = null;
        isOffline = true;
      } else {
        error = 'Error al cargar historial: $e';
        isOffline = true;
      }
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Calcula estadísticas usando isolate para no bloquear el hilo principal
  Future<void> _calculateStats(List<Reservation> reservations) async {
    try {
      final reservationsData = reservations.map((r) => {
        'dayOfWeek': r.slotStart.weekday,
        'hour': r.slotStart.hour,
      }).toList();

      final calculatedStats = await compute(_HistoryStatsProcessor.process, reservationsData);
      stats = calculatedStats;
      notifyListeners();
    } catch (e) {
      // Error al calcular estadísticas - ignorar
    }
  }

  /// 🔹 ESTRATEGIA DE ALMACENAMIENTO LOCAL: Guarda en SharedPreferences
  /// Clave: 'cached_history_reservations'
  /// Formato: JSON array de reservas
  Future<void> _saveToCache(List<Reservation> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((r) => r.toJson()).toList();
      final jsonStr = jsonEncode(list);
      await prefs.setString('cached_history_reservations', jsonStr);
      await prefs.setInt(
        'cached_history_reservations_time',
        DateTime.now().millisecondsSinceEpoch,
      );
      print('🔹 [HistoryViewModel] Guardado en SharedPreferences: ${items.length} reservas');
      print('🔹 [HistoryViewModel] Clave: cached_history_reservations');
      print('🔹 [HistoryViewModel] Tamaño JSON: ${jsonStr.length} caracteres');
    } catch (e) {
      print('❌ [HistoryViewModel] Error al guardar en cache: $e');
    }
  }

  /// 🔹 ESTRATEGIA DE ALMACENAMIENTO LOCAL: Carga desde SharedPreferences
  /// Lee la clave 'cached_history_reservations' y deserializa las reservas
  Future<List<Reservation>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_history_reservations');
      if (jsonStr == null || jsonStr.isEmpty) {
        print('🔹 [HistoryViewModel] No hay datos en cache (SharedPreferences vacío)');
        return [];
      }

      final list = jsonDecode(jsonStr) as List;
      final reservations = list.map((json) => Reservation.fromJson(json as Map<String, dynamic>)).toList();
      print('🔹 [HistoryViewModel] Cargado desde SharedPreferences: ${reservations.length} reservas');
      print('🔹 [HistoryViewModel] Clave: cached_history_reservations');
      return reservations;
    } catch (e) {
      print('❌ [HistoryViewModel] Error al cargar desde cache: $e');
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
      if (cached.isNotEmpty) {
        await _calculateStats(cached);
      }
      historyReservations = cached;
      notifyListeners();
    }
  }
}

/// 🔹 Clase estática para procesar estadísticas en isolate
class _HistoryStatsProcessor {
  static Map<String, dynamic> process(List<Map<String, dynamic>> reservationsData) {
    if (reservationsData.isEmpty) {
      return {
        'favoriteDays': [],
        'favoriteHours': [],
      };
    }

    // Días favoritos (día de la semana)
    final Map<int, int> dayCount = {};
    for (final r in reservationsData) {
      final day = r['dayOfWeek'] as int;
      dayCount[day] = (dayCount[day] ?? 0) + 1;
    }

    final dayEntries = dayCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxDayCount = dayEntries.isNotEmpty ? dayEntries.first.value : 0;
    final favoriteDays = dayEntries
        .where((e) => e.value == maxDayCount)
        .map((e) => e.key)
        .toList();

    // Horas favoritas
    final Map<int, int> hourCount = {};
    for (final r in reservationsData) {
      final hour = r['hour'] as int;
      hourCount[hour] = (hourCount[hour] ?? 0) + 1;
    }

    final hourEntries = hourCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final maxHourCount = hourEntries.isNotEmpty ? hourEntries.first.value : 0;
    final favoriteHours = hourEntries
        .where((e) => e.value == maxHourCount)
        .map((e) => e.key)
        .toList()
      ..sort();

    return {
      'favoriteDays': favoriteDays,
      'favoriteHours': favoriteHours,
    };
  }
}

