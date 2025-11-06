import 'package:flutter/material.dart';
import '../../../domain/repositories/host_repository.dart';
import '../../../domain/repositories/space_repository.dart';
import '../../../domain/entities/host.dart';
import '../../../domain/entities/space.dart';

class HostViewModel extends ChangeNotifier {
  final HostRepository hostRepo;
  final SpaceRepository spaceRepo;

  HostViewModel(this.hostRepo, this.spaceRepo);

  bool isLoading = false;
  String? error;
  Host? currentHost;
  List<Space> mySpaces = [];

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

  Future<void> loadMyHostProfile() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      currentHost = await hostRepo.getMyHostProfile();
    } catch (e) {
      error = 'Error: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }



  Future<void> loadMySpaces() async {
    if (currentHost == null) {
      error = 'Debes cargar el perfil del host antes de obtener sus espacios';
      notifyListeners();
      return;
    }

    try {
      isLoading = true;
      error = null;
      notifyListeners();

      mySpaces = await spaceRepo.getSpacesByHost(currentHost!.id);
    } catch (e) {
      error = 'Error al cargar espacios: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Crear un nuevo espacio para el host actual
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

      // Asegurar que el espacio se vincule al host actual
      data['hostProfileId'] = currentHost!.id;

      final newSpace = await spaceRepo.createSpace(data);
      mySpaces.add(newSpace);

      notifyListeners();
      return true;
    } catch (e) {
      error = 'Error al crear el espacio: $e';
      notifyListeners();
      return false;
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
    mySpaces.clear();
    isLoading = false;
    notifyListeners();
  }
}
