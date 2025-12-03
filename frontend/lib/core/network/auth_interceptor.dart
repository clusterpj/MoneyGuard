import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final authBox = Hive.box('auth');
    final token = authBox.get('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Clear invalid token
      final authBox = Hive.box('auth');
      await authBox.clear();
      // Optionally, you could trigger a logout event here
      // but the auth provider will detect missing token on next build.
    }
    super.onError(err, handler);
  }
}