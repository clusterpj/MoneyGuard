import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<Expense>> getExpenses({int page = 1, int limit = 20});
  Future<Expense> createExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime transactionDate,
  });
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final ApiClient _apiClient;

  ExpenseRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<Expense>> getExpenses({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/expenses',
        queryParameters: {'skip': (page - 1) * limit, 'limit': limit},
      );

      if (response.statusCode == 200) {
        // Backend returns array directly, not wrapped in object
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
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/expenses',
        data: {
          'amount': amount,
          'description': description,
          'category': category,
          'transaction_date': transactionDate.toIso8601String(),
          'source': 'manual',
        },
      );

      if (response.statusCode == 201) {
        return Expense.fromJson(response.data);
      }
      throw Exception('Failed to create expense');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }
}
