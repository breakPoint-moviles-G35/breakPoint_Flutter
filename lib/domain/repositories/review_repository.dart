import '../entities/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviewsBySpace(String spaceId);
  Future<Map<String, dynamic>> getSpaceStats(String spaceId);

  Future<void> createReview({
    required String spaceId,
    required String text,
    required String rating, // 1..5 en string, acorde al backend
  });
}
