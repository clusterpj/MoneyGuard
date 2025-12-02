import 'package:flutter/material.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class BudgetSummaryCard extends StatelessWidget {
  final Budget budget;

  const BudgetSummaryCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final spent = budget.spent ?? 0.0;
    final remaining = budget.calculatedRemaining;
    final percentageUsed = budget.calculatedPercentageUsed.clamp(0, 100);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.name ?? 'Budget Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    Chip(
                      label: Text('${budget.daysRemaining} days left'),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        context.push('/budget/setup', extra: budget);
                      },
                      tooltip: 'Edit Budget',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Remaining Amount - Prominent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: remaining > 0
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    remaining > 0 ? 'Remaining' : 'Over Budget',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    // Wrapped Text with GestureDetector
                    onTap: () {
                      // Navigate to budget edit
                      context.push('/budget/setup', extra: budget);
                    },
                    child: Text(
                      currencyFormat.format(remaining.abs()),
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: remaining > 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.red.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Spent: ${currencyFormat.format(spent)}'),
                    Text('${percentageUsed.toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (percentageUsed / 100).clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: percentageUsed > 100 ? Colors.red : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Budget: ${currencyFormat.format(budget.amount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
