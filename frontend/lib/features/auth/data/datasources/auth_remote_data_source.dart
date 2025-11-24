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
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // The API returns data inside 'data' field, and user info might be there or we might need to fetch profile.
        // Based on API docs:
        // Login response: { success: true, data: { access_token: ..., refresh_token: ..., expires_in: ... } }
        // It does NOT return user details directly in login response, only tokens.
        // We might need to fetch profile after login or construct a partial user.
        // Let's assume we need to fetch profile or the backend should return it.
        // Checking API docs again...
        // Login response only has tokens.
        // Register response has user_id, email, name, tokens.

        final data = response.data['data'];
        // For login, we only get tokens. We should probably fetch the user profile immediately.
        // Or we can return a User with just tokens and fetch profile later.
        // Let's fetch profile here to return a complete User object.

        final accessToken = data['access_token'];
        _apiClient.dio.options.headers['Authorization'] = 'Bearer $accessToken';

        final profileResponse = await _apiClient.dio.get('/user/profile');
        if (profileResponse.statusCode == 200 &&
            profileResponse.data['success'] == true) {
          final profileData = profileResponse.data['data'];
          return User(
            id: profileData['id'],
            email: profileData['email'],
            name: profileData['name'],
            // phone: profileData['phone'], // Profile might not have phone? API docs say it returns id, email, name, intervention_mode...
            accessToken: accessToken,
            refreshToken: data['refresh_token'],
          );
        }
        throw Exception('Failed to fetch user profile');
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
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
