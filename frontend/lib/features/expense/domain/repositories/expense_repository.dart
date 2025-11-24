import 'package:moneyguard/features/expense/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({int page = 1, int limit = 20});
  Future<Expense> createExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime transactionDate,
  });
}
