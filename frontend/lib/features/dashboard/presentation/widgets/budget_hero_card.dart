import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/shared/widgets/circular_budget_progress.dart';

class BudgetHeroCard extends StatelessWidget {
  final Budget? budget;
  final bool isLoading;

  const BudgetHeroCard({
    super.key,
    required this.budget,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (budget == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [AppColors.buttonGlow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Budget',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up a budget to track your spending.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('createBudgetButton'),
              onPressed: () => context.push('/budget/setup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accentStart,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Create Budget',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(
      symbol: 'RD\$',
      decimalDigits: 0,
    );
    final remaining = budget!.calculatedRemaining;
    final spent = budget!.spent ?? 0;
    final total = budget!.amount;
    final percentage = budget!.calculatedPercentageUsed / 100;
    final daysLeft = budget!.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentStart.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundSecondary,
            AppColors.backgroundSecondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.accentStart.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget!.name ?? 'Monthly Budget',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentStart.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$daysLeft days left',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accentStart,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                key: const Key('editBudgetButton'),
                onPressed: () => context.push('/budget/setup', extra: budget),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Row(
            children: [
              CircularBudgetProgress(percentage: percentage),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REMAINING', style: AppTypography.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      key: const Key('budgetRemainingAmount'),
                      currencyFormat.format(remaining),
                      style: AppTypography.displayLarge.copyWith(fontSize: 28),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Spent',
                                style: AppTypography.labelSmall,
                              ),
                              Text(
                                key: const Key('budgetSpentAmount'),
                                currencyFormat.format(spent),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Budget',
                                style: AppTypography.labelSmall,
                              ),
                              Text(
                                currencyFormat.format(total),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
