import '../entities/space.dart';
import '../entities/space_detail.dart';

abstract class SpaceRepository {
  Future<List<Space>> search({
    String query,
    bool sortAsc,
    String? start,
    String? end,
  });

  Future<Space> getById(String id);
  
  Future<SpaceDetail> getSpaceDetails(String id);
}
