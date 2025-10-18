import '../entities/host.dart';

abstract class HostRepository {
  /// Crear un nuevo perfil de host
  Future<Host> createHostProfile({
    required String verificationStatus,
    required String payoutMethod,
    required String userId,
  });

  /// Obtener todos los perfiles de host (incluye user, spaces, spaces.reviews)
  Future<List<Host>> getAllHostProfiles();

  /// Obtener el perfil del usuario autenticado
  Future<Host> getMyHostProfile();

  /// Obtener un perfil de host por ID
  Future<Host> getHostProfileById(String id);

  /// Obtener el host de un espacio específico
  Future<Host?> getHostBySpaceId(String spaceId);
}
