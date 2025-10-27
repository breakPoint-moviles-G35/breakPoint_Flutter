import '../entities/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviewsBySpace(String spaceId);
  Future<Map<String, dynamic>> getSpaceStats(String spaceId);
}
