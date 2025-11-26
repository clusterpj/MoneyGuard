import 'package:moneyguard/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;

  ExpenseRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    return await _remoteDataSource.getExpenses(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
    );
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
    return await _remoteDataSource.createExpense(
      amount: amount,
      description: description,
      category: category,
      transactionDate: transactionDate,
      source: source,
      ocrRawText: ocrRawText,
      ocrConfidence: ocrConfidence,
    );
  }

  @override
  Future<Expense> uploadReceipt(String filePath) async {
    return await _remoteDataSource.uploadReceipt(filePath);
  }

  @override
  Future<Expense> updateExpense(String id, Expense expense) async {
    return await _remoteDataSource.updateExpense(id, expense.toJson());
  }

  @override
  Future<void> deleteExpense(String id) async {
    return await _remoteDataSource.deleteExpense(id);
  }
}
