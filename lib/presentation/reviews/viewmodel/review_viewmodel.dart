import 'package:flutter/material.dart';
import '../../../../domain/entities/review.dart';
import '../../../../domain/repositories/review_repository.dart';

class ReviewViewModel extends ChangeNotifier {
  final ReviewRepository _repository;

  List<Review> reviews = [];
  double averageRating = 0;
  int reviewCount = 0;
  bool isLoading = false;
  String? errorMessage;

  ReviewViewModel(this._repository);

  Future<void> loadReviews(String spaceId) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      reviews = await _repository.getReviewsBySpace(spaceId);
      final stats = await _repository.getSpaceStats(spaceId);
      averageRating = (stats['average_rating'] ?? 0).toDouble();
      reviewCount = stats['review_count'] ?? 0;
    } catch (e) {
      errorMessage = 'Error al cargar reviews: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
