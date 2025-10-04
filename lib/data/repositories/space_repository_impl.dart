import '../../domain/entities/space.dart';
import '../../domain/repositories/space_repository.dart';
import '../services/space_api.dart';

class SpaceRepositoryImpl implements SpaceRepository {
  final SpaceApi api;
  SpaceRepositoryImpl(this.api);

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

    // usamos el mapeo de Space.fromJson
    return data.map((j) => Space.fromJson(j)).toList();
  }

  @override
  Future<Space> getById(String id) async {
    final j = await api.getSpaceById(id);
    return Space.fromJson(j);
  }
}