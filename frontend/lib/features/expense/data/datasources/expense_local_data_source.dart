import 'package:hive/hive.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';

abstract class ExpenseLocalDataSource {
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });

  Future<Expense> getExpense(String id);

  Future<void> saveExpense(Expense expense);

  Future<void> saveExpenses(List<Expense> expenses);

  Future<void> updateExpense(Expense expense);

  Future<void> deleteExpense(String id);

  Future<void> clear();
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  static const String _boxName = 'expenses';

  Box<Expense> get _box => Hive.box<Expense>(_boxName);

  @override
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    List<Expense> all = _box.values.toList();

    // Apply filters
    if (startDate != null) {
      all = all.where((e) => e.transactionDate.isAfter(startDate) || e.transactionDate.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      all = all.where((e) => e.transactionDate.isBefore(endDate) || e.transactionDate.isAtSameMomentAs(endDate)).toList();
    }
    if (categoryId != null) {
      // Note: categoryId is not stored in Expense entity (only category name).
      // For simplicity, we'll filter by category name if we have mapping.
      // For now, skip categoryId filter.
    }

    // Sort by date descending
    all.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return all;
  }

  @override
  Future<Expense> getExpense(String id) async {
    final expense = _box.values.firstWhere((e) => e.id == id, orElse: () => throw Exception('Expense not found'));
    return expense;
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    await _box.put(expense.id, expense);
  }

  @override
  Future<void> saveExpenses(List<Expense> expenses) async {
    final Map<String, Expense> map = { for (var e in expenses) e.id : e };
    await _box.putAll(map);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await saveExpense(expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}