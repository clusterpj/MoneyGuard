import 'package:moneyguard/features/expense/domain/entities/expense.dart';

abstract class ExpenseRepository {
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

  Future<Expense> updateExpense(String id, Expense expense);

  Future<void> deleteExpense(String id);
}
