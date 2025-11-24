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

final recentExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  // Watch auth state to refetch when user logs in/out
  ref.watch(authStateProvider);

  final repository = ref.read(expenseRepositoryProvider);
  return await repository.getExpenses(limit: 5);
});
