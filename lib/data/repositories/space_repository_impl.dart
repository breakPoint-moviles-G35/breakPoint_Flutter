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

    return data.map((j) {
  final dynamic priceRaw = j['price'];
  final dynamic ratingRaw = j['rating'];

  final double price = priceRaw is num
      ? priceRaw.toDouble()
      : double.tryParse(priceRaw.toString()) ?? 0.0;

  final double rating = ratingRaw is num
      ? ratingRaw.toDouble()
      : double.tryParse(ratingRaw.toString()) ?? 0.0;

  return Space(
    id: j['id'].toString(),
    title: j['title'] ?? '',
    subtitle: j['subtitle'] ?? '',
    imageUrl: j['imageUrl'] ?? '',
    price: price,
    rating: rating,
  );
}).toList();

  }
}
