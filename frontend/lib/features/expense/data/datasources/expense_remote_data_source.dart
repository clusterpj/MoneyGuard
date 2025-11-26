import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });

  Future<Expense> createExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime transactionDate,
    String? source,
    String? ocrRawText,
    double? ocrConfidence,
  });

  Future<Expense> uploadReceipt(String filePath);

  Future<Expense> updateExpense(String id, Map<String, dynamic> data);

  Future<void> deleteExpense(String id);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final ApiClient _apiClient;

  ExpenseRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'skip': (page - 1) * limit,
        'limit': limit,
      };

      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (categoryId != null) queryParams['category_id'] = categoryId;

      final response = await _apiClient.dio.get(
        '/expenses',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final expenses = (response.data as List)
            .map((json) => Expense.fromJson(json))
            .toList();
        return expenses;
      }
      throw Exception('Failed to fetch expenses');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Expense> createExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime transactionDate,
    String? source,
    String? ocrRawText,
    double? ocrConfidence,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/expenses',
        data: {
          'amount': amount,
          'description': description,
          'category':
              category, // This might need to be category_id if backend expects UUID
          'transaction_date': transactionDate.toIso8601String(),
          'source': source ?? 'manual',
          'ocr_raw_text': ocrRawText,
          'ocr_confidence': ocrConfidence,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Expense.fromJson(response.data);
      }
      throw Exception('Failed to create expense');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Expense> uploadReceipt(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _apiClient.dio.post(
        '/expenses/upload-receipt',
        data: formData,
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data);
      }
      throw Exception('Failed to upload receipt');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Expense> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/expenses/$id', data: data);

      if (response.statusCode == 200) {
        return Expense.fromJson(response.data);
      }
      throw Exception('Failed to update expense');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      final response = await _apiClient.dio.delete('/expenses/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete expense');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }
}
