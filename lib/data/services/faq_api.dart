import 'package:dio/dio.dart';

class FaqApi {
  final Dio dio;
  FaqApi(this.dio);

  Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final res = await dio.get('/faq/question');
      return (res.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> getThread(String id) async {
    try {
      final res = await dio.get('/faq/question/$id');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> createQuestion({
    required String title,
    required String question,
  }) async {
    try {
      final res = await dio.post('/faq/question', data: {
        'title': title,
        'question': question,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e));
    }
  }

  Future<Map<String, dynamic>> createAnswer({
    required String questionId,
    required String text,
  }) async {
    try {
      final res = await dio.post('/faq/answer', data: {
        'question_id': questionId,
        'text': text,
      });
      return Map<String, dynamic>.from(res.data);
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
