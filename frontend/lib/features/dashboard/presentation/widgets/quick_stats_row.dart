import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/domain/entities/expense_category.dart';
import 'package:moneyguard/shared/widgets/stat_card.dart';

class QuickStatsRow extends StatelessWidget {
  final List<Expense> expenses;

  const QuickStatsRow({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactSimpleCurrency(
      name: 'RD\$',
    ); // Compact for small cards

    // Calculate totals by category
    final Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      // expense.category is the ID
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    // Sort by amount descending and take top 3
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(3).toList();

    // If fewer than 3, fill with placeholders or just show what we have
    // Design shows 3 cards. If no data, maybe show "No data" or empty slots.
    // Let's show top 3 or defaults if empty.

    if (topCategories.isEmpty) {
      return const SizedBox.shrink(); // Or show empty state
    }

    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i < topCategories.length)
            StatCard(
              emoji: ExpenseCategory.fromId(topCategories[i].key).emoji,
              value: currencyFormat.format(topCategories[i].value),
              label: ExpenseCategory.fromId(topCategories[i].key).name,
            )
          else
            const Spacer(), // Placeholder for empty slots to maintain layout if needed, or just nothing

          if (i < 2) const SizedBox(width: 12), // Spacing between cards
        ],
      ],
    );
  }
}
