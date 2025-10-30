import 'package:dio/dio.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../services/review_api.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewApi _api;

  ReviewRepositoryImpl(this._api);

  /// Obtiene todas las reviews asociadas a un espacio específico
  @override
  Future<List<Review>> getReviewsBySpace(String spaceId) async {
    try {
      final response = await _api.getReviewsBySpace(spaceId);
      return response.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener reviews: $e');
    }
  }

  /// Obtiene las estadísticas (promedio, cantidad, etc.) de las reviews de un espacio
  @override
  Future<Map<String, dynamic>> getSpaceStats(String spaceId) async {
    try {
      return await _api.getSpaceStats(spaceId);
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  @override
  Future<void> createReview({
    required String spaceId,
    required String text,
    required String rating,
  }) async {
    try {
      await _api.createReview(spaceId: spaceId, text: text, rating: rating);
    } catch (e) {
      throw Exception('Error al crear review: $e');
    }
  }

  /// 🔹 Nuevo método para obtener el promedio de rating de un espacio
  Future<double> fetchAverageRatingForSpace(int spaceId) async {
    try {
      final stats = await _api.getSpaceStats(spaceId.toString());
      // Espera una respuesta tipo: {"averageRating": 4.6, "reviewCount": 15}
      return (stats["averageRating"] ?? 0.0).toDouble();
    } catch (e) {
      print("⚠️ Error al obtener el promedio de rating para espacio $spaceId: $e");
      return 0.0;
    }
  }
}
