import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';

class InterventionDialog extends ConsumerWidget {
  const InterventionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervention = ref.watch(interventionProvider);
    if (intervention == null) {
      return const SizedBox.shrink();
    }

    final message = intervention['message'] as String? ?? 'This expense may exceed your budget.';
    final reasons = intervention['reasons'] as List<dynamic>? ?? [];

    // Determine severity based on reasons
    final isSevere = reasons.contains('exceeds_remaining_budget');
    final color = isSevere ? AppColors.error : AppColors.warning;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isSevere ? Icons.warning_amber : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 12),
          Text(
            isSevere ? 'Budget Alert' : 'Spending Advice',
            style: AppTypography.headlineMedium.copyWith(color: color),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: AppTypography.bodyLarge,
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Reasons:',
              style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            ...reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: Text(
                    '• ${_reasonText(reason)}',
                    style: AppTypography.bodyMedium,
                  ),
                )),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(interventionProvider.notifier).clear();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            ref.read(interventionProvider.notifier).clear();
            Navigator.of(context).pop();
            // Optionally, you could trigger a follow-up action (e.g., open budget screen)
          },
          child: const Text('Proceed Anyway'),
        ),
      ],
    );
  }

  String _reasonText(dynamic reason) {
    if (reason == 'exceeds_remaining_budget') {
      return 'Exceeds remaining budget';
    } else if (reason == 'large_purchase') {
      return 'Large purchase (over 20% of budget)';
    }
    return reason.toString();
  }
}