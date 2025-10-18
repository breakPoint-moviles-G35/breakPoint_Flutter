import '../../domain/entities/host.dart';
import '../../domain/repositories/host_repository.dart';
import '../services/host_api.dart';

class HostRepositoryImpl implements HostRepository {
  final HostApi _api;

  HostRepositoryImpl(this._api);

  @override
  Future<Host> createHostProfile({
    required String verificationStatus,
    required String payoutMethod,
    required String userId,
  }) async {
    try {
      final response = await _api.createHostProfile(
        verificationStatus: verificationStatus,
        payoutMethod: payoutMethod,
        userId: userId,
      );
      return Host.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear el perfil de host: $e');
    }
  }

  @override
  Future<List<Host>> getAllHostProfiles() async {
    try {
      final response = await _api.getAllHostProfiles();
      return response.map((json) => Host.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener los perfiles de host: $e');
    }
  }

  @override
  Future<Host> getMyHostProfile() async {
    try {
      final response = await _api.getMyHostProfile();
      return Host.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener mi perfil de host: $e');
    }
  }

  @override
  Future<Host> getHostProfileById(String id) async {
    try {
      final response = await _api.getHostProfileById(id);
      return Host.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener el perfil de host: $e');
    }
  }

  @override
  Future<Host?> getHostBySpaceId(String spaceId) async {
    try {
      final hosts = await getAllHostProfiles();
      
      // Buscar el host que tenga el spaceId en sus espacios
      for (var host in hosts) {
        if (host.spaces != null) {
          for (var space in host.spaces!) {
            if (space['id'] == spaceId) {
              return host;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Error al obtener el host del espacio: $e');
    }
  }
}
