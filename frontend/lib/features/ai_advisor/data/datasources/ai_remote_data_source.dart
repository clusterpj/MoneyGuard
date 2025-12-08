import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';

abstract class AiRemoteDataSource {
  Future<String> sendMessage(String message);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final ApiClient _apiClient;

  AiRemoteDataSourceImpl(this._apiClient);

  @override
  Future<String> sendMessage(String message) async {
    try {
      final response = await _apiClient.dio.post(
        '/ai/chat',
        data: {'message': message},
      );
      return response.data['response'];
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['detail'] ?? 'Failed to get response');
      }
      throw Exception('Network error');
    }
  }
}
