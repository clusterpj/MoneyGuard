import 'package:moneyguard/features/budget/data/datasources/budget_remote_data_source.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/features/budget/domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetRemoteDataSource _remoteDataSource;

  BudgetRepositoryImpl(this._remoteDataSource);

  @override
  Future<Budget?> getCurrentBudget() async {
    return await _remoteDataSource.getCurrentBudget();
  }

  @override
  Future<Budget> createBudget(
    double totalAmount,
    String period,
    DateTime startDate,
  ) async {
    return await _remoteDataSource.createBudget(totalAmount, period, startDate);
  }
}
