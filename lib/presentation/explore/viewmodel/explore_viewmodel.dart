import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../../../domain/repositories/space_repository.dart';
import '../../../domain/entities/space.dart';
import '../../../data/services/review_api.dart';
import '../../../data/repositories/review_repository_impl.dart';

class ExploreViewModel extends ChangeNotifier {
  final SpaceRepository repo;
  bool _initialized = false;
  ExploreViewModel(this.repo);

  // Estado general
  final TextEditingController searchCtrl = TextEditingController();
  bool sortAsc = true;

  String? start;
  String? end;

  bool isLoading = false;
  String? error;
  List<Space> spaces = [];
  bool isOffline = false;

  // Estado para recomendaciones
  bool isLoadingRecommendations = false;
  String? recommendationsError;
  List<Space> recommendations = [];

  // Helpers
  bool get hasRange => start != null && end != null;

  // Instancia del repositorio de reviews
  final ReviewRepositoryImpl _reviewRepo = ReviewRepositoryImpl(
    ReviewApi(Dio(BaseOptions(baseUrl: 'http://192.168.177.247:3000'))),
  );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // estado inicial
    final initial = await Connectivity()
        .checkConnectivity(); // List<ConnectivityResult>
    isOffline = initial.contains(ConnectivityResult.none);

    // Carga espacios y recomendaciones en paralelo y espera a ambas
    await Future.wait([
      load(),
      loadRecommendations(),
    ]);

    // escuchar cambios
  }

  Future<void> retry() async {
    final list = await Connectivity().checkConnectivity();
    final hasNetwork =
        list.isNotEmpty && !list.contains(ConnectivityResult.none);
    isOffline = !hasNetwork;

    if (hasNetwork) {
      await load(); // refresca y cachea
    } else {
      await _loadSpacesFromCache(); // muestra lo que haya guardado
      error = null;
      notifyListeners(); // mantiene visible el banner
    }
  }

  void _applySort() {
    // Si algún precio pudiera venir nulo, protege con ?? 0.0
    spaces.sort(
      (a, b) =>
          sortAsc ? a.price.compareTo(b.price) : b.price.compareTo(a.price),
    );
  }

  // -------------------------------------------------------
  // Cargar espacios normales con rating real
  // -------------------------------------------------------

  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final list = await Connectivity()
          .checkConnectivity(); // List<ConnectivityResult>
      final hasNetwork =
          list.isNotEmpty && !list.contains(ConnectivityResult.none);
      isOffline = !hasNetwork;
      if (!hasNetwork) {
        final ok = await _loadSpacesFromCache();
        if (!ok) {
          error =
              'Sin conexión. No hay datos en caché.'; // solo si no hay nada que mostrar
        } else {
          error = null;
          _applySort();
        }
        notifyListeners();
        return;
      }

      // Con red: intenta del backend
      try {
        spaces = await repo.search(
          query: searchCtrl.text,
          sortAsc: sortAsc,
          start: start,
          end: end,
        );

        await Future.wait(
          spaces.map((space) async {
            try {
              final stats = await _reviewRepo.getSpaceStats(
                space.id.toString(),
              );
              if (stats.containsKey("average_rating")) {
                space.rating = (stats["average_rating"] ?? 0.0).toDouble();
              }
            } catch (_) {}
          }),
        );

        await _saveSpacesToCache(spaces);
        _applySort();
        notifyListeners();
        error = null; // hay datos frescos
      } catch (e) {
        // Si falla la red o el backend, cae a caché
        final ok = await _loadSpacesFromCache();
        if (!ok) {
          error = 'Error de conexión: $e'; // no hay caché → muestra error
        } else {
          error = null; // hay caché → NO mostramos error
          _applySort();
        }
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------
  // Cargar recomendaciones personalizadas
  // -------------------------------------------------------
  Future<void> loadRecommendations() async {
    try {
      isLoadingRecommendations = true;
      recommendationsError = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null || userId.isEmpty) {
        recommendations = [];
        return;
      }

      recommendations = await repo.getRecommendations(userId);

      // 🔹 También actualizar rating real de los recomendados en paralelo
      await Future.wait(
        recommendations.map((space) async {
          try {
            final stats = await _reviewRepo.getSpaceStats(space.id.toString());
            if (stats.containsKey("average_rating")) {
              space.rating = (stats["average_rating"] ?? 0.0).toDouble();
            }
          } catch (e) {
            print("⚠️ Error al cargar rating de recomendación ${space.id}: $e");
          }
        }),
      );

      notifyListeners();
    } catch (e) {
      recommendationsError = 'Error: $e';
    } finally {
      isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------
  // Otros métodos de control
  // -------------------------------------------------------
  void toggleSort() {
    sortAsc = !sortAsc;
    _applySort();
    notifyListeners();
  }

  // Convierte un DateTimeRange a dos strings ISO y recarga
  void setStartEndFromRange(DateTimeRange? range) {
    if (range == null) {
      start = null;
      end = null;
    } else {
      start = range.start.toIso8601String();
      end = range.end.toIso8601String();
    }
    load();
  }

  // Formato YYYY-MM-DD para chip
  String fmtIsoDay(String iso) => iso.substring(0, 10);

  void onQueryChanged(String _) => load();

  // ==========================
  // Cache local de espacios
  // ==========================
  Future<void> _saveSpacesToCache(List<Space> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items
          .map(
            (s) => {
              'id': s.id,
              'title': s.title,
              'subtitle': s.subtitle,
              'price': s.price,
              'rating': s.rating,
              'imageUrl': s.imageUrl,
              'capacity': s.capacity,
              'rules': s.rules,
              'amenities': s.amenities,
            },
          )
          .toList();
      // Guardar como string JSON
      final jsonString = const JsonEncoder().convert(list);
      await prefs.setString('cached_spaces', jsonString);
      await prefs.setInt(
        'cached_spaces_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Silenciar errores de caché
    }
  }

  Future<bool> _loadSpacesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('cached_spaces');
      if (jsonString == null || jsonString.isEmpty) {
        spaces = [];
        return false; // no hay caché
      }
      final List<dynamic> list = const JsonDecoder().convert(jsonString);
      spaces = list.map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        return Space(
          id: map['id']?.toString() ?? '',
          title: map['title'] ?? '',
          subtitle: map['subtitle'],
          geo: null,
          capacity: (map['capacity'] as int?) ?? 0,
          amenities:
              (map['amenities'] as List?)?.map((e) => e.toString()).toList() ??
              [],
          accessibility: null,
          rules: map['rules'] ?? '',
          price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
          rating: (map['rating'] is num)
              ? (map['rating'] as num).toDouble()
              : 0.0,
          imageUrl: map['imageUrl'] ?? '',
        );
      }).toList();
      return spaces.isNotEmpty; // sí hay caché utilizable
    } catch (_) {
      spaces = [];
      return false;
    }
  }
}
