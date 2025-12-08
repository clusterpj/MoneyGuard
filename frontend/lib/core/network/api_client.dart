import 'dart:async';
import 'package:dio/dio.dart';
import 'package:moneyguard/core/config/config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio _dio;
  final _authErrorController = StreamController<void>.broadcast();

  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: Config.apiBaseUrl,
          connectTimeout: Config.connectTimeout,
          receiveTimeout: Config.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      AuthInterceptor(onAuthError: () => _authErrorController.add(null)),
    );
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;
  Stream<void> get authErrorStream => _authErrorController.stream;
}
