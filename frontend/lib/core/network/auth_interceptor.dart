import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthInterceptor extends Interceptor {
  final VoidCallback? onAuthError;

  AuthInterceptor({this.onAuthError});

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
      onAuthError?.call();
    }
    super.onError(err, handler);
  }
}
