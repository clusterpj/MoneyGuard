import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';
import 'package:moneyguard/features/auth/domain/entities/user.dart';

abstract class AuthRemoteDataSource {
  Future<User> login(String email, String password);
  Future<User> register(
    String email,
    String password,
    String name,
    String phone,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<User> login(String email, String password) async {
    try {
      // OAuth2PasswordRequestForm expects 'username' and 'password' as form data
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': email, // OAuth2 uses 'username' field
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (response.statusCode == 200) {
        // Login response: { access_token: ..., token_type: ... }
        final data = response.data;
        final accessToken = data['access_token'];
        _apiClient.dio.options.headers['Authorization'] = 'Bearer $accessToken';

        // Fetch user profile
        final profileResponse = await _apiClient.dio.get('/user/profile');
        if (profileResponse.statusCode == 200) {
          final profileData = profileResponse.data;
          return User(
            id: profileData['id'],
            email: profileData['email'],
            name: profileData['full_name'] ?? profileData['email'],
            accessToken: accessToken,
            refreshToken:
                null, // Login doesn't return refresh token in current implementation
          );
        }
        throw Exception('Failed to fetch user profile');
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<User> register(
    String email,
    String password,
    String name,
    String phone,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return User.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}
