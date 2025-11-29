import '../../domain/entities/space.dart';
import '../../domain/repositories/space_repository.dart';
import '../services/space_api.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  final SpaceApi api;
  SpaceRepositoryImpl(this.api);

  /// Buscar espacios con filtros
  @override
  Future<List<Space>> search({
    String query = '',
    bool sortAsc = true,
    String? start,
    String? end,
  }) async {
    final data = await api.searchSpaces(
      query: query.isEmpty ? null : query,
      sortAsc: sortAsc,
      start: start,
      end: end,
    );

    return data.map((j) => Space.fromJson(j)).toList();
  }

  /// Obtener espacio por ID
  @override
  Future<Space> getById(String id) async {
    final j = await api.getSpaceById(id);
    return Space.fromJson(j);
  }

  /// Obtener el espacio más cercano
  @override
  Future<Space> getNearest({
    required double latitude,
    required double longitude,
  }) async {
    final j = await api.getNearestSpace(
      latitude: latitude,
      longitude: longitude,
    );
    return Space.fromJson(j);
  }

  /// Obtener recomendaciones personalizadas
  @override
  Future<List<Space>> getRecommendations(String userId) async {
    final data = await api.getRecommendations(userId);
    return data.map((j) => Space.fromJson(j)).toList();
  }


  /// Obtener todos los espacios publicados por un host específico
  @override
  Future<List<Space>> getSpacesByHost(String hostProfileId) async {
    try {
      final data = await api.getSpacesByHost(hostProfileId);
      return data.map((j) => Space.fromJson(j)).toList();
    } catch (e) {
      throw Exception('Error al obtener los espacios del host: $e');
    }
  }

  /// Crear un nuevo espacio vinculado a un HostProfile
  @override
  Future<Space> createSpace(Map<String, dynamic> data) async {
    try {
      final json = await api.createSpace(data);
      return Space.fromJson(json);
    } catch (e) {
      throw Exception('Error al crear el espacio: $e');
    }
  }
}
