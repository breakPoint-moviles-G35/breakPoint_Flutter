import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/space_repository.dart';
import '../../../domain/entities/space.dart';

class ExploreViewModel extends ChangeNotifier {
  final SpaceRepository repo;
  ExploreViewModel(this.repo);

  // Estado
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

  // Acciones
  Future<void> load() async {
    try {
      isLoading = true; error = null; notifyListeners();
      spaces = await repo.search(
        query: searchCtrl.text,
        sortAsc: sortAsc,
        start: start,
        end: end,
      );
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false; notifyListeners();
    }
  }

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
    } catch (e) {
      recommendationsError = 'Error: $e';
    } finally {
      isLoadingRecommendations = false; 
      notifyListeners();
    }
  }

  void toggleSort() { sortAsc = !sortAsc; load(); }

  // Convierte un DateTimeRange a dos strings ISO y recarga
  void setStartEndFromRange(DateTimeRange? range) {
    if (range == null) {
      start = null;
      end = null;
    } else {
      start = range.start.toIso8601String();
      end   = range.end.toIso8601String();
    }
    load();
  }

  // Formato YYYY-MM-DD para chip
  String fmtIsoDay(String iso) => iso.substring(0, 10);

  void onQueryChanged(String _) => load();
}
