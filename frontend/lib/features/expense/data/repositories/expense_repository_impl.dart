import 'package:moneyguard/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;

  ExpenseRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Expense>> getExpenses({int page = 1, int limit = 20}) async {
    return await _remoteDataSource.getExpenses(page: page, limit: limit);
  }

  @override
  Future<Expense> createExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime transactionDate,
  }) async {
    return await _remoteDataSource.createExpense(
      amount: amount,
      description: description,
      category: category,
      transactionDate: transactionDate,
    );
  }
}
