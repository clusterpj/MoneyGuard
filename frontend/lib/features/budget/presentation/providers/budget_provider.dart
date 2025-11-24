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

final budgetProvider = FutureProvider<Budget?>((ref) async {
  // Watch auth state to refetch when user logs in/out
  ref.watch(authStateProvider);

  final repository = ref.read(budgetRepositoryProvider);
  return await repository.getCurrentBudget();
});
