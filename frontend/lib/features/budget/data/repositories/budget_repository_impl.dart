import 'package:moneyguard/features/budget/data/datasources/budget_remote_data_source.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/features/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource _remoteDataSource;

  BudgetRepositoryImpl(this._remoteDataSource);

  @override
  Future<Budget?> getCurrentBudget({String? categoryId}) async {
    return await _remoteDataSource.getCurrentBudget(categoryId: categoryId);
  }

  @override
  Future<List<Budget>> getBudgets() async {
    return await _remoteDataSource.getBudgets();
  }

  @override
  Future<List<Budget>> getBudgetAnalytics() async {
    return await _remoteDataSource.getBudgetAnalytics();
  }

  @override
  Future<Budget> getBudget(String id) async {
    return await _remoteDataSource.getBudget(id);
  }

  @override
  Future<Budget> createBudget({
    String? name,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
  }) async {
    return await _remoteDataSource.createBudget(
      name: name,
      amount: amount,
      period: period,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
    );
  }

  @override
  Future<Budget> updateBudget(String id, Budget budget) async {
    return await _remoteDataSource.updateBudget(id, budget);
  }

  @override
  Future<void> deleteBudget(String id) async {
    return await _remoteDataSource.deleteBudget(id);
  }
}
