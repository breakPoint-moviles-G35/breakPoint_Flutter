import 'package:flutter/material.dart';
import '../../../domain/entities/review.dart';
import '../../../domain/repositories/review_repository.dart';

class ReviewSummaryViewModel extends ChangeNotifier {
  final ReviewRepository _repository;

  ReviewSummaryViewModel(this._repository);

  bool isLoading = false;
  Review? featuredReview;
  double averageRating = 0;
  int reviewCount = 0;

  Future<void> loadReviewSummary(String spaceId) async {
    try {
      isLoading = true;
      notifyListeners();

      // Cargar reviews y estadísticas
      final reviews = await _repository.getReviewsBySpace(spaceId);
      final stats = await _repository.getSpaceStats(spaceId);

      if (reviews.isNotEmpty) {
        featuredReview = reviews.first;
      }
      averageRating = (stats['average_rating'] ?? 0).toDouble();
      reviewCount = stats['review_count'] ?? 0;
    } catch (e) {
      debugPrint('Error cargando resumen de reviews: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
