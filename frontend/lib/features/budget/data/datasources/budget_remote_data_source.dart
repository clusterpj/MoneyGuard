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
        '/budgets/current',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return Budget.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<List<Budget>> getBudgets() async {
    try {
      final response = await _apiClient.dio.get('/budgets');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Budget.fromJson(json))
            .toList();
      }
      throw Exception('Failed to get budgets');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<List<Budget>> getBudgetAnalytics() async {
    try {
      final response = await _apiClient.dio.get('/budgets/analytics');
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Budget.fromJson(json))
            .toList();
      }
      throw Exception('Failed to get budget analytics');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Budget> getBudget(String id) async {
    try {
      final response = await _apiClient.dio.get('/budgets/$id');
      if (response.statusCode == 200) {
        return Budget.fromJson(response.data);
      }
      throw Exception('Failed to get budget');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Budget> createBudget({
    String? name,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? emoji,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/budgets',
        data: {
          if (name != null) 'name': name,
          'amount': amount,
          'period': period,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          if (categoryId != null) 'category_id': categoryId,
          if (emoji != null) 'emoji': emoji,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Budget.fromJson(response.data);
      }
      throw Exception('Failed to create budget');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<Budget> updateBudget(String id, Budget budget) async {
    try {
      final response = await _apiClient.dio.put(
        '/budgets/$id',
        data: budget.toJson(),
      );

      if (response.statusCode == 200) {
        return Budget.fromJson(response.data);
      }
      throw Exception('Failed to update budget');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _apiClient.dio.delete('/budgets/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? e.message);
    }
  }
}
