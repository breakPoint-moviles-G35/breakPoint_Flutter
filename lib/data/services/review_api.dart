import 'package:dio/dio.dart';

class ReviewApi {
  final Dio dio;
  ReviewApi(this.dio);

  Future<List<Map<String, dynamic>>> getReviewsBySpace(String spaceId) async {
    try {
      final res = await dio.get('/review/space/$spaceId');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> getSpaceStats(String spaceId) async {
    try {
      final res = await dio.get('/review/space/$spaceId/stats');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<void> createReview({
    required String spaceId,
    required String text,
    required String rating,
  }) async {
    try {
      await dio.post('/review', data: {
        'spaceId': spaceId,
        'text': text,
        'rating': rating, // en string
      });
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    var msg = 'Error de red';
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      if (m is String) msg = m;
      if (m is List && m.isNotEmpty) msg = m.first.toString();
    } else if (e.message != null) {
      msg = e.message!;
    }
    return msg;
  }
}
