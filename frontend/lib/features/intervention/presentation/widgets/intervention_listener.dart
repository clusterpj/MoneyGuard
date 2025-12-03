import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';
import 'intervention_dialog.dart';

class InterventionListener extends ConsumerWidget {
  const InterventionListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<Map<String, dynamic>?>(
      interventionProvider,
      (previous, next) {
        if (next != null && previous != next) {
          // Show dialog
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const InterventionDialog(),
            );
          });
        }
      },
    );

    return child;
  }
}