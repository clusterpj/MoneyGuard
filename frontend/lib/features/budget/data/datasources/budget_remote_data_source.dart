import 'package:dio/dio.dart';
import 'package:moneyguard/core/network/api_client.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';

abstract class BudgetRemoteDataSource {
  Future<Budget?> getCurrentBudget({String? categoryId});
  Future<List<Budget>> getBudgets();
  Future<List<Budget>> getBudgetAnalytics();
  Future<Budget> getBudget(String id);
  Future<Budget> createBudget({
    String? name,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? emoji,
  });
  Future<Budget> updateBudget(String id, Budget budget);
  Future<void> deleteBudget(String id);
}

class BudgetRemoteDataSourceImpl implements BudgetRemoteDataSource {
  final ApiClient _apiClient;

  BudgetRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Budget?> getCurrentBudget({String? categoryId}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _apiClient.dio.get(
        '/budgets/current/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

// ...

      final response = await _apiClient.dio.get('/budgets/');

// ...

      final response = await _apiClient.dio.get('/budgets/analytics/');

// ...

      final response = await _apiClient.dio.get('/budgets/$id/');

// ...

      final response = await _apiClient.dio.post(
        '/budgets/',
        data: {

// ...

      final response = await _apiClient.dio.put(
        '/budgets/$id/',
        data: budget.toJson(),
      );

// ...

      await _apiClient.dio.delete('/budgets/$id/');
}
