import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Estado para recomendaciones
  bool isLoadingRecommendations = false;
  String? recommendationsError;
  List<Space> recommendations = [];

  // Helpers
  bool get hasRange => start != null && end != null;

  // Instancia del repositorio de reviews
  final ReviewRepositoryImpl _reviewRepo =
      ReviewRepositoryImpl(ReviewApi(Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'))));

  // -------------------------------------------------------
  // Cargar espacios normales con rating real
  // -------------------------------------------------------
  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      // 1️⃣ Obtener los espacios del backend principal
      spaces = await repo.search(
        query: searchCtrl.text,
        sortAsc: sortAsc,
        start: start,
        end: end,
      );

      // 2️⃣ Para cada espacio, traer el rating real desde Review API
      for (final space in spaces) {
        try {
          final stats = await _reviewRepo.getSpaceStats(space.id.toString());
          if (stats.containsKey("average_rating")) {
            space.rating = (stats["average_rating"] ?? 0.0).toDouble();
          }
        } catch (e) {
          // Ignorar errores individuales para no romper todo el ciclo
          print("⚠️ Error al cargar rating del espacio ${space.id}: $e");
        }
      }

      notifyListeners();
    } catch (e) {
      error = 'Error: $e';
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
      for (final space in recommendations) {
        try {
          final stats = await _reviewRepo.getSpaceStats(space.id.toString());
          if (stats.containsKey("average_rating")) {
            space.rating = (stats["average_rating"] ?? 0.0).toDouble();
          }
        } catch (e) {
          print("⚠️ Error al cargar rating de recomendación ${space.id}: $e");
        }
      }

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
}
