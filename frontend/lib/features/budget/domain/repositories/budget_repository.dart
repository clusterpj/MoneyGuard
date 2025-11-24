import 'package:moneyguard/features/budget/domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<Budget?> getCurrentBudget();
  Future<Budget> createBudget(
    double totalAmount,
    String period,
    DateTime startDate,
  );
}
