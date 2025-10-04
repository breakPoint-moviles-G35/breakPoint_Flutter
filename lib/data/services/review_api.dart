import 'package:dio/dio.dart';

class ReviewApi {
  final Dio dio;
  ReviewApi(this.dio);

  Future<List<Map<String, dynamic>>> getReviewsBySpaceId(String spaceId) async {
    final res = await dio.get('/reviews/space/$spaceId');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAllReviews() async {
    final res = await dio.get('/reviews');
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getReviewById(String id) async {
    final res = await dio.get('/reviews/$id');
    return res.data as Map<String, dynamic>;
  }
}


