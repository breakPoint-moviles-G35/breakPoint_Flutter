import '../entities/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviewsBySpaceId(String spaceId);
  Future<List<Review>> getAllReviews();
  Future<Review> getReviewById(String id);
}


