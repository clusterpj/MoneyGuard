import 'package:moneyguard/features/budget/domain/entities/budget.dart';

abstract class BudgetRepository {
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
  });
  Future<Budget> updateBudget(String id, Budget budget);
  Future<void> deleteBudget(String id);
}
