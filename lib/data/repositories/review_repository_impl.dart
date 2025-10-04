import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../services/review_api.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewApi api;
  ReviewRepositoryImpl(this.api);

  @override
  Future<List<Review>> getReviewsBySpaceId(String spaceId) async {
    final data = await api.getReviewsBySpaceId(spaceId);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  @override
  Future<List<Review>> getAllReviews() async {
    final data = await api.getAllReviews();
    return data.map((json) => Review.fromJson(json)).toList();
  }

  @override
  Future<Review> getReviewById(String id) async {
    final data = await api.getReviewById(id);
    return Review.fromJson(data);
  }
}
