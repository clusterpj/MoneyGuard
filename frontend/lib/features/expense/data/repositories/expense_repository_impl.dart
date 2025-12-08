import 'package:moneyguard/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:moneyguard/features/expense/data/datasources/expense_local_data_source.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;
  final ExpenseLocalDataSource _localDataSource;

  ExpenseRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<Expense>> getExpenses({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      // Try to fetch from remote
      final remoteExpenses = await _remoteDataSource.getExpenses(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      // Store fetched expenses locally (replace existing)
      await _localDataSource.saveExpenses(remoteExpenses);
      return remoteExpenses;
    } catch (e) {
      // If remote fails, fallback to local data
      final localExpenses = await _localDataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      // Apply pagination locally (simple slice)
      final start = (page - 1) * limit;
      final end = start + limit;
      if (start >= localExpenses.length) return [];
      return localExpenses.sublist(
        start,
        end < localExpenses.length ? end : localExpenses.length,
      );
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
      final expense = await _remoteDataSource.createExpense(
        amount: amount,
        description: description,
        category: category,
        transactionDate: transactionDate,
        source: source,
        ocrRawText: ocrRawText,
        ocrConfidence: ocrConfidence,
      );
      // Save to local storage
      await _localDataSource.saveExpense(expense);
      return expense;
    } catch (e) {
      // If offline, we could store locally with a pending sync flag.
      // For MVP, we'll just rethrow the error (no offline creation).
      rethrow;
    }
  }

  @override
  Future<Expense> uploadReceipt(String filePath) async {
    final expense = await _remoteDataSource.uploadReceipt(filePath);
    // Save to local storage
    await _localDataSource.saveExpense(expense);
    return expense;
  }

  @override
  Future<Expense> updateExpense(String id, Expense expense) async {
    final updated = await _remoteDataSource.updateExpense(id, expense.toJson());
    await _localDataSource.updateExpense(updated);
    return updated;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _remoteDataSource.deleteExpense(id);
    await _localDataSource.deleteExpense(id);
  }
}
