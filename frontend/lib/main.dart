import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moneyguard/core/theme/theme.dart';
import 'package:moneyguard/features/auth/presentation/providers/auth_provider.dart';
import 'package:moneyguard/features/auth/presentation/screens/login_screen.dart';
import 'package:moneyguard/features/auth/presentation/screens/register_screen.dart';
import 'package:moneyguard/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:moneyguard/features/budget/presentation/screens/budget_setup_screen.dart';
import 'package:moneyguard/features/expense/presentation/screens/add_expense_screen.dart';
import 'package:moneyguard/features/expense/presentation/screens/expense_list_screen.dart';
import 'package:moneyguard/features/expense/presentation/screens/import_screen.dart';
import 'package:moneyguard/features/budget/presentation/screens/budget_list_screen.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/data/adapters/expense_hive_adapter.dart';
import 'package:moneyguard/features/intervention/presentation/widgets/intervention_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  await Hive.openBox('auth');
  await Hive.openBox<Expense>('expenses');

  runApp(const ProviderScope(child: MoneyGuardApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';

      if (!isLoggedIn && !isLoggingIn && !isRegistering) return '/login';
      if (isLoggedIn && (isLoggingIn || isRegistering)) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/budget/setup',
        builder: (context, state) {
          final budget = state.extra as Budget?;
          return BudgetSetupScreen(budgetToEdit: budget);
        },
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpenseListScreen(),
      ),
      GoRoute(
        path: '/expenses/add',
        builder: (context, state) {
          final expense = state.extra as Expense?;
          return AddExpenseScreen(expenseToEdit: expense);
        },
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetListScreen(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportScreen(),
      ),
    ],
  );
});

class MoneyGuardApp extends ConsumerWidget {
  const MoneyGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return InterventionListener(
      child: MaterialApp.router(
        title: 'MoneyGuard',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
