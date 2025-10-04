import 'package:dio/dio.dart';

class SpaceApi {
  final Dio dio;
  SpaceApi(this.dio);

  Future<List<Map<String, dynamic>>> searchSpaces({
    String? query,
    bool sortAsc = true,
    String? start,
    String? end,
  }) async {
    final qp = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'q': query,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
    };

    final res = await dio.get(
      sortAsc ? '/space/sorted' : '/space',
      queryParameters: qp,
    );

    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getSpaceById(String id) async {
    final res = await dio.get('/space/$id');
    return res.data as Map<String, dynamic>;
  }
}

