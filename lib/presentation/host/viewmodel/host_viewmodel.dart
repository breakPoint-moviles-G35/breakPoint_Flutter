import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../domain/repositories/host_repository.dart';
import '../../../domain/repositories/space_repository.dart';
import '../../../domain/entities/host.dart';
import '../../../domain/entities/space.dart';
import 'dart:isolate';

class HostSpacesStats {
  final int totalSpaces;
  final int totalCapacity;
  final double avgPrice;
  final double avgRating;

  HostSpacesStats({
    required this.totalSpaces,
    required this.totalCapacity,
    required this.avgPrice,
    required this.avgRating,
  });
}


///   VIEWMODEL COMPLETO

class HostViewModel extends ChangeNotifier {
  final HostRepository hostRepo;
  final SpaceRepository spaceRepo;

  HostViewModel(this.hostRepo, this.spaceRepo);

  bool isLoading = false;
  String? error;
  Host? currentHost;
  List<Space> mySpaces = [];

  HostSpacesStats? stats;

  
  ///                CARGA DE PERFIL DEL HOST
  

  Future<void> loadMyHostProfile() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      currentHost = await hostRepo.getMyHostProfile();
    } catch (e) {
      error = 'Error al cargar el perfil del host: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHostById(String hostId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      currentHost = await hostRepo.getHostProfileById(hostId);
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHostBySpaceId(String spaceId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      currentHost = await hostRepo.getHostBySpaceId(spaceId);
      if (currentHost == null) {
        error = 'No se encontró información del host para este espacio';
      }
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  
  ///     ALMACENAMIENTO LOCAL (SharedPreferences)
  

  Future<void> _cacheMySpaces() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      mySpaces.map((s) => s.toJson()).toList(),
    );
    await prefs.setString('my_spaces_cache', encoded);
  }

  Future<void> _loadSpacesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('my_spaces_cache');

    if (cached != null) {
      final decoded = jsonDecode(cached) as List;
      mySpaces = decoded.map((e) => Space.fromJson(e)).toList();
      notifyListeners(); 
    }
  }

  
  ///     CARGA DE ESPACIOS DEL HOST (OFFLINE)
  

  Future<void> loadMySpaces() async {
    
    await _loadSpacesFromCache();

    
    if (currentHost == null) {
      error = null;
      return;
    }

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      
      mySpaces = await spaceRepo.getSpacesByHost(currentHost!.id);

      
      await _cacheMySpaces();

      
      await _computeStatsInBackground();

    } catch (e) {
      
      await _loadSpacesFromCache();
      error = null; 
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  

  Future<bool> createSpace(Map<String, dynamic> data) async {
    if (currentHost == null) {
      error = 'No hay host autenticado';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      data['hostProfileId'] = currentHost!.id;

      final newSpace = await spaceRepo.createSpace(data);
      mySpaces.add(newSpace);

      // Actualizar cache
      await _cacheMySpaces();

      // Recalcular estadísticas
      await _computeStatsInBackground();

      return true;
    } catch (e) {
      error = 'Error al crear el espacio: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  

  void clearError() {
    error = null;
    notifyListeners();
  }

  void clearHost() {
    currentHost = null;
    error = null;
    mySpaces.clear();
    isLoading = false;
    notifyListeners();
  }

  
  ///     CÁLCULO DE ESTADÍSTICAS EN ISOLATE (CONCURRENCIA)
  

  Future<void> _computeStatsInBackground() async {
    if (mySpaces.isEmpty) {
      stats = null;
      return;
    }

    final capacities = mySpaces.map((s) => s.capacity).toList();
    final prices = mySpaces.map((s) => s.price).toList();
    final ratings = mySpaces.map((s) => s.rating).toList();

    final result = await Isolate.run<Map<String, dynamic>>(() {
      final total = capacities.length;
      final totalCapacity = capacities.fold<int>(0, (sum, c) => sum + c);

      final totalPrice = prices.fold<double>(0, (sum, p) => sum + p);
      final totalRating = ratings.fold<double>(0, (sum, r) => sum + r);

      return {
        'totalSpaces': total,
        'totalCapacity': totalCapacity,
        'avgPrice': prices.isEmpty ? 0.0 : totalPrice / prices.length,
        'avgRating': ratings.isEmpty ? 0.0 : totalRating / ratings.length,
      };
    });

    stats = HostSpacesStats(
      totalSpaces: result['totalSpaces'],
      totalCapacity: result['totalCapacity'],
      avgPrice: result['avgPrice'],
      avgRating: result['avgRating'],
    );

    notifyListeners();
  }
}
