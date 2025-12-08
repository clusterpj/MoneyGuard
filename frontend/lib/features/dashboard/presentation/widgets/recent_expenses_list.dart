import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';
import 'package:moneyguard/features/expense/presentation/widgets/expense_list_item.dart';

class RecentExpensesList extends ConsumerWidget {
  final List<Expense> expenses;

  const RecentExpensesList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No recent expenses', style: AppTypography.bodyMedium),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/expenses'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.accentStart,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.take(5).length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return ExpenseListItem(
              key: Key('expense_item_$index'),
              expense: expense,
              onTap: () {
                // Navigate to details or edit
                context.push('/expenses/edit', extra: expense);
              },
              onDelete: () async {
                await ref
                    .read(expenseListProvider.notifier)
                    .deleteExpense(expense.id);
              },
            );
          },
        ),
      ],
    );
  }
}
