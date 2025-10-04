import 'package:dio/dio.dart';

class HostApi {
  final Dio dio;
  HostApi(this.dio);

  Future<Map<String, dynamic>> getHostById(String id) async {
    final res = await dio.get('/host-profiles/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHostByUserId(String userId) async {
    final res = await dio.get('/host-profiles/user/$userId');
    return res.data as Map<String, dynamic>;
  }
}
