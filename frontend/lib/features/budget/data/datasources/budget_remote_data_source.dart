import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';

abstract class BudgetRemoteDataSource {
  Future<Budget?> getCurrentBudget();
  Future<Budget> createBudget(
    double totalAmount,
    String period,
    DateTime startDate,
  );
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final ApiClient _apiClient;

  BudgetRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Budget?> getCurrentBudget() async {
    try {
      final response = await _apiClient.dio.get('/budgets/current');

      if (response.statusCode == 200) {
        return Budget.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No budget exists yet
      }
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Budget> createBudget(
    double totalAmount,
    String period,
    DateTime startDate,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/budgets',
        data: {
          'total_amount': totalAmount,
          'period': period,
          'start_date': startDate.toIso8601String().split('T')[0], // YYYY-MM-DD
        },
      );

      if (response.statusCode == 201) {
        return Budget.fromJson(response.data);
      }
      throw Exception('Failed to create budget');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }
}
