import 'package:flutter/material.dart';
import '../../../domain/repositories/host_repository.dart';
import '../../../domain/entities/host.dart';

class HostViewModel extends ChangeNotifier {
  final HostRepository repo;
  HostViewModel(this.repo);

  // Estado
  bool isLoading = false;
  String? error;
  Host? currentHost;

  // Acciones
  Future<void> loadHostById(String hostId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      currentHost = await repo.getHostProfileById(hostId);
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

      currentHost = await repo.getHostBySpaceId(spaceId);
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

  Future<void> loadMyHostProfile() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      currentHost = await repo.getMyHostProfile();
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }

  void clearHost() {
    currentHost = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
