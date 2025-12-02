import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:moneyguard/features/expense/data/datasources/expense_remote_data_source.dart';
import 'package:moneyguard/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/domain/repositories/expense_repository.dart';

final expenseRemoteDataSourceProvider = Provider<ExpenseRemoteDataSource>((
  ref,
) {
  return ExpenseRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.read(expenseRemoteDataSourceProvider));
});

class ExpenseFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;

  ExpenseFilters({this.startDate, this.endDate, this.categoryId});

  ExpenseFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) {
    return ExpenseFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

class ExpenseList extends AsyncNotifier<List<Expense>> {
  ExpenseFilters _filters = ExpenseFilters();

  @override
  Future<List<Expense>> build() async {
    // Watch auth state to reset when user logs out/in
    ref.watch(authStateProvider);
    return _loadExpenses();
  }

  Future<List<Expense>> _loadExpenses() async {
    final repository = ref.read(expenseRepositoryProvider);
    return repository.getExpenses(
      startDate: _filters.startDate,
      endDate: _filters.endDate,
      categoryId: _filters.categoryId,
    );
  }

  void updateFilters(ExpenseFilters filters) {
    _filters = filters;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> createExpense({
    required double amount,
    required String description,
    required String category,
    required DateTime transactionDate,
    String? source,
    String? ocrRawText,
    double? ocrConfidence,
  }) async {
    final repository = ref.read(expenseRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createExpense(
        amount: amount,
        description: description,
        category: category,
        transactionDate: transactionDate,
        source: source,
        ocrRawText: ocrRawText,
        ocrConfidence: ocrConfidence,
      );
      return _loadExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    final repository = ref.read(expenseRepositoryProvider);
    final previousState = state;

    // Optimistic update
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.where((e) => e.id != id).toList());
    }

    try {
      await repository.deleteExpense(id);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateExpense(String id, Expense expense) async {
    final repository = ref.read(expenseRepositoryProvider);
    try {
      final updatedExpense = await repository.updateExpense(id, expense);
      if (state.hasValue) {
        final expenses = state.value!
            .map((e) => e.id == id ? updatedExpense : e)
            .toList();
        state = AsyncValue.data(expenses);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Expense> uploadReceipt(String filePath) async {
    final repository = ref.read(expenseRepositoryProvider);
    return await repository.uploadReceipt(filePath);
  }
}

final expenseListProvider = AsyncNotifierProvider<ExpenseList, List<Expense>>(
  () {
    return ExpenseList();
  },
);

final recentExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expensesState = ref.watch(expenseListProvider);
  return expensesState.whenData((expenses) => expenses.take(5).toList());
});
