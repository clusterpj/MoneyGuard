import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:moneyguard/features/budget/data/datasources/budget_remote_data_source.dart';
import 'package:moneyguard/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/features/budget/domain/repositories/budget_repository.dart';

final budgetRemoteDataSourceProvider = Provider<BudgetRemoteDataSource>((ref) {
  return BudgetRemoteDataSourceImpl(ref.read(apiClientProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepositoryImpl(ref.read(budgetRemoteDataSourceProvider));
});

class BudgetList extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    // Watch auth state to reset when user logs out/in
    ref.watch(authStateProvider);
    return _loadBudgets();
  }

  Future<List<Budget>> _loadBudgets() async {
    final repository = ref.read(budgetRepositoryProvider);
    return repository.getBudgets();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addBudget({
    String? name,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? emoji,
  }) async {
    final repository = ref.read(budgetRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.createBudget(
        name: name,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        emoji: emoji,
      );
      // Invalidate current budget to refresh dashboard
      ref.invalidate(currentBudgetProvider);
      return _loadBudgets();
    });
  }

  Future<void> updateBudget(String id, Budget budget) async {
    final repository = ref.read(budgetRepositoryProvider);
    try {
      final updatedBudget = await repository.updateBudget(id, budget);
      if (state.hasValue) {
        final budgets = state.value!
            .map((b) => b.id == id ? updatedBudget : b)
            .toList();
        state = AsyncValue.data(budgets);
        // Invalidate current budget to refresh dashboard
        ref.invalidate(currentBudgetProvider);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    final repository = ref.read(budgetRepositoryProvider);
    final previousState = state;

    // Optimistic update
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.where((b) => b.id != id).toList());
    }

    try {
      await repository.deleteBudget(id);
      // Invalidate current budget to refresh dashboard
      ref.invalidate(currentBudgetProvider);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }
}

final budgetListProvider = AsyncNotifierProvider<BudgetList, List<Budget>>(() {
  return BudgetList();
});

final budgetAnalyticsProvider = FutureProvider<List<Budget>>((ref) async {
  ref.watch(authStateProvider);
  final repository = ref.read(budgetRepositoryProvider);
  return repository.getBudgetAnalytics();
});

final currentBudgetProvider = FutureProvider.family<Budget?, String?>((
  ref,
  categoryId,
) async {
  ref.watch(authStateProvider);
  final repository = ref.read(budgetRepositoryProvider);
  return repository.getCurrentBudget(categoryId: categoryId);
});
