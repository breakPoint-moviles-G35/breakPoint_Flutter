import 'package:dio/dio.dart';

typedef TokenProvider = String? Function();

class DioClient {
  final Dio _dio;

  DioClient(String baseUrl, {TokenProvider? tokenProvider})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ) {
    // Interceptor para Authorization (primero, para que LogInterceptor lo registre ya aplicado)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    // Logger después, para ver el header Authorization en los logs
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  Dio get dio => _dio;
}
