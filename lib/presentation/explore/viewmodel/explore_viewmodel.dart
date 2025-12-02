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
  ExploreViewModel(this.repo) {
    _loadLastViewed(); 
  }

  // Estado general
  final TextEditingController searchCtrl = TextEditingController();
  bool sortAsc = true;

  String? start;
  String? end;

  bool isLoading = false;
  String? error;
  List<Space> spaces = [];
  bool isOffline = false;

  // Estado recomendaciones
  bool isLoadingRecommendations = false;
  String? recommendationsError;
  List<Space> recommendations = [];

  bool get hasRange => start != null && end != null;

  final ReviewRepositoryImpl _reviewRepo =
      ReviewRepositoryImpl(ReviewApi(Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'))));

  
  static const _kLastViewedKey = "last_viewed_spaces";
  List<Space> _lastViewed = [];

  List<Space> get lastViewed => _lastViewed;

  Future<void> addToRecent(Space space) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Eliminar si ya existe
      _lastViewed.removeWhere((s) => s.id == space.id);

      // Insertar al inicio
      _lastViewed.insert(0, space);

      // Limitar a 5
      if (_lastViewed.length > 5) {
        _lastViewed = _lastViewed.sublist(0, 5);
      }

      // Guardar en cache
      final jsonList =
          _lastViewed.map((s) => jsonEncode(_spaceToMinimalJson(s))).toList();

      await prefs.setStringList(_kLastViewedKey, jsonList);

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadLastViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kLastViewedKey);

      if (raw == null) return;

      final decoded = raw
          .map((e) => jsonDecode(e))
          .map((m) => Space.fromJson(Map<String, dynamic>.from(m)))
          .toList();

      _lastViewed = decoded;
      notifyListeners();
    } catch (_) {}
  }

  // ============================================================
  // Cargar espacios
  // ============================================================
  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = connectivity != ConnectivityResult.none;
      isOffline = !hasInternet;

      if (!hasInternet) {
        final cached = await _loadCachedSpaces();
        spaces = cached;
        notifyListeners();
      } else {
        spaces = await repo.search(
          query: searchCtrl.text,
          sortAsc: sortAsc,
          start: start,
          end: end,
        );

        // cargar rating real
        await Future.wait(spaces.map((space) async {
          try {
            final stats = await _reviewRepo.getSpaceStats(space.id.toString());
            if (stats.containsKey("average_rating")) {
              space.rating = (stats["average_rating"] ?? 0.0).toDouble();
            }
          } catch (_) {}
        }));

        await _saveCachedSpaces(spaces);
      }

      notifyListeners();
    } catch (e) {
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

  // ============================================================
  // Recomendaciones
  // ============================================================
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

      await Future.wait(recommendations.map((space) async {
        try {
          final stats = await _reviewRepo.getSpaceStats(space.id.toString());
          if (stats.containsKey("average_rating")) {
            space.rating = (stats["average_rating"] ?? 0.0).toDouble();
          }
        } catch (_) {}
      }));

      notifyListeners();
    } catch (e) {
      recommendationsError = 'Error: $e';
    } finally {
      isLoadingRecommendations = false;
      notifyListeners();
    }
  }

  
  void toggleSort() {
    sortAsc = !sortAsc;
    load();
  }

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

  // ============================================================
  // Cache de espacios
  // ============================================================
  static const _kCachedSpaces = 'cached_spaces_v1';

  Future<void> _saveCachedSpaces(List<Space> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = list.map(_spaceToMinimalJson).toList();
      await prefs.setString(_kCachedSpaces, jsonEncode(payload));
    } catch (_) {}
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
    };
  }
}
