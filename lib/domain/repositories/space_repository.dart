import '../entities/space.dart';

abstract class SpaceRepository {
  Future<List<Space>> search({
    String query,
    bool sortAsc,
    String? start,
    String? end,
  });

  Future<Space> getById(String id);

  Future<Space> getNearest({
    required double latitude,
    required double longitude,
  });

  Future<List<Space>> getRecommendations(String userId);
}
