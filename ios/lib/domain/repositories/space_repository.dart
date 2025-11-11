import '../entities/space.dart';

abstract class SpaceRepository {
  /// 🔹 Buscar espacios según filtros
  Future<List<Space>> search({
    String query,
    bool sortAsc,
    String? start,
    String? end,
  });

  /// Obtener un espacio por su ID
  Future<Space> getById(String id);

  /// Obtener el espacio más cercano según ubicación
  Future<Space> getNearest({
    required double latitude,
    required double longitude,
  });

  /// Obtener recomendaciones personalizadas para un usuario
  Future<List<Space>> getRecommendations(String userId);

  /// Obtener todos los espacios publicados por un host específico
  Future<List<Space>> getSpacesByHost(String hostProfileId);

  /// Crear un nuevo espacio vinculado a un HostProfile
  Future<Space> createSpace(Map<String, dynamic> data);
}
