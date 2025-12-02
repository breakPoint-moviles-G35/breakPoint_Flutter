import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../domain/repositories/space_repository.dart';
import '../../../domain/entities/space.dart';
import '../../../data/services/review_api.dart';
import '../../../data/repositories/review_repository_impl.dart';

class ExploreViewModel extends ChangeNotifier {
  final SpaceRepository repo;
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
  final ReviewRepositoryImpl _reviewRepo =

      ReviewRepositoryImpl(ReviewApi(Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'))));

  // 🔹 ESTRATEGIA DE CACHING: HashMap en memoria para ratings de espacios
  // Clave: spaceId (String), Valor: rating (double)
  final Map<String, double> _ratingCache = {};
  // -------------------------------------------------------
  // Cargar espacios normales con rating real
  // -------------------------------------------------------
  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = connectivity != ConnectivityResult.none;
      isOffline = !hasInternet;

      if (!hasInternet) {
        // 🔹 Sin internet: cargar cache local
        final cached = await _loadCachedSpaces();
        spaces = cached;
        notifyListeners();
      } else {
        // 1️⃣ Obtener los espacios del backend principal
        spaces = await repo.search(
          query: searchCtrl.text,
          sortAsc: sortAsc,
          start: start,
          end: end,
        );

      // 2️⃣ Para cada espacio, traer el rating real desde Review API
      // 🔹 Usar cache HashMap para evitar llamadas repetidas
      await Future.wait(spaces.map((space) async {
        try {
          final spaceId = space.id.toString();
          
          // Verificar si el rating está en cache
          if (_ratingCache.containsKey(spaceId)) {
            space.rating = _ratingCache[spaceId]!;
            return;
          }
          
          // Si no está en cache, obtener de la API
          final stats = await _reviewRepo.getSpaceStats(spaceId);
          if (stats.containsKey("average_rating")) {
            final rating = (stats["average_rating"] ?? 0.0).toDouble();
            space.rating = rating;
            // Guardar en cache
            _ratingCache[spaceId] = rating;
          }
        } catch (e) {
          // Ignorar errores individuales para no romper todo el ciclo
          print("⚠️ Error al cargar rating del espacio ${space.id}: $e");
        }
      }));

        // 🔹 Guardar en cache local sin imágenes
        await _saveCachedSpaces(spaces);
      }

      notifyListeners();
    } catch (e) {
      // Intentar cargar desde cache si hubo error al conectar
      isOffline = true;
      final cached = await _loadCachedSpaces();
      if (cached.isNotEmpty) {
        spaces = cached;
        error = null;
      } else {
        error = 'Error: $e';
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

      // 🔹 También actualizar rating real de los recomendados
      // 🔹 Usar cache HashMap para evitar llamadas repetidas
      await Future.wait(recommendations.map((space) async {
        try {
          final spaceId = space.id.toString();
          
          // Verificar si el rating está en cache
          if (_ratingCache.containsKey(spaceId)) {
            space.rating = _ratingCache[spaceId]!;
            return;
          }
          
          // Si no está en cache, obtener de la API
          final stats = await _reviewRepo.getSpaceStats(spaceId);
          if (stats.containsKey("average_rating")) {
            final rating = (stats["average_rating"] ?? 0.0).toDouble();
            space.rating = rating;
            // Guardar en cache
            _ratingCache[spaceId] = rating;
          }
        } catch (e) {
          print("⚠️ Error al cargar rating de recomendación ${space.id}: $e");
        }
      }));

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
    load();
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

  Future<void> retry() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet = connectivity != ConnectivityResult.none;
    isOffline = !hasInternet;
    if (hasInternet) {
      await load();
    } else {
      spaces = await _loadCachedSpaces();
      notifyListeners();
    }
  }

  // -------------------------------------------------------
  // Cache local de espacios (sin imagen)
  // -------------------------------------------------------
  static const _kCachedSpaces = 'cached_spaces_v1';

  Future<void> _saveCachedSpaces(List<Space> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = list.map(_spaceToMinimalJson).toList();
      await prefs.setString(_kCachedSpaces, jsonEncode(payload));
    } catch (_) {
      // Ignorar errores de cache
    }
  }

  Future<List<Space>> _loadCachedSpaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedSpaces);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map((j) => Space.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _spaceToMinimalJson(Space s) {
    return {
      'id': s.id,
      'title': s.title,
      'subtitle': s.subtitle,
      'geo': s.geo,
      'capacity': s.capacity,
      'amenities': s.amenities,
      'accessibility': s.accessibility,
      'rules': s.rules,
      'price': s.price,
      'rating': s.rating,
      // imageUrl intencionalmente omitido
    };
  }
}
