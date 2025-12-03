import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';

class InterventionRemoteDataSource {
  final ApiClient _apiClient;

  InterventionRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> checkIntervention({
    required double amount,
    required String category,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/intervention/check',
        data: {
          'amount': amount,
          'category': category,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }
}