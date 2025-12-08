import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/features/expense/domain/entities/expense_category.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';
import 'package:moneyguard/shared/widgets/gradient_button.dart';
import 'package:moneyguard/shared/widgets/selectable_chip.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  String? _selectedCategoryId;
  double? _selectedAmount;
  bool _isCustomAmount = false;
  final TextEditingController _customAmountController = TextEditingController();

  // Default quick amounts
  final List<double> _quickAmounts = [100, 250, 500, 1000, 2500, 5000];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  void _handleCategorySelect(String id) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategoryId = id;
    });
    _tryAutoSave();
  }

  void _handleAmountSelect(double amount) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedAmount = amount;
      _isCustomAmount = false;
    });
    _tryAutoSave();
  }

  void _handleCustomAmount() async {
    HapticFeedback.selectionClick();
    setState(() {
      _isCustomAmount = true;
      _selectedAmount = null;
    });

    // Show dialog or bottom sheet for number input could go here
    // For now, we'll just focus a text field if we were to show one,
    // but the design calls for a specific button.
    // Let's implement a simple dialog for custom amount for now.
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _CustomAmountDialog(),
    );

    if (amount != null) {
      setState(() {
        _selectedAmount = amount;
      });
      _tryAutoSave();
    } else {
      setState(() {
        _isCustomAmount = false;
      });
    }
  }

  void _tryAutoSave() {
    // The requirement says "SaveButton (gradient, disabled until selection complete)"
    // But also mentions "Zero typing".
    // "On save: create expense with current date, selected category, selected amount"
    // Let's stick to the manual save button for safety unless "Auto-save" was explicitly requested as *immediate* action.
    // The prompt says: "SaveButton (gradient, disabled until selection complete)" -> So manual save.
  }

  Future<void> _saveExpense() async {
    if (_selectedCategoryId == null || _selectedAmount == null) return;

    HapticFeedback.mediumImpact();

    try {
      final category = ExpenseCategory.fromId(_selectedCategoryId!);

      await ref
          .read(expenseListProvider.notifier)
          .createExpense(
            amount: _selectedAmount!,
            description: category.name,
            category: category.id,
            transactionDate: DateTime.now(),
          );

      if (mounted) {
        context.pop(); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense saved! 🎉'),
            backgroundColor: AppColors.backgroundSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = _selectedCategoryId != null && _selectedAmount != null;
    final currencyFormat = NumberFormat.currency(
      symbol: 'RD\$',
      decimalDigits: 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: SingleChildScrollView(
        key: const Key('quickAddSheetScroll'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.backgroundTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Quick Add',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Categories
            const Text(
              'What did you spend on?',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: ExpenseCategory.defaults.length,
              itemBuilder: (context, index) {
                final category = ExpenseCategory.defaults[index];
                return SelectableChip(
                  label: category.name,
                  emoji: category.emoji,
                  isSelected: _selectedCategoryId == category.id,
                  onTap: () => _handleCategorySelect(category.id),
                );
              },
            ),
            const SizedBox(height: 32),

            // Amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('How much? (RD\$)', style: AppTypography.labelLarge),
                if (_selectedAmount != null && _isCustomAmount)
                  Text(
                    currencyFormat.format(_selectedAmount),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.accentStart,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: _quickAmounts.length,
              itemBuilder: (context, index) {
                final amount = _quickAmounts[index];
                return SelectableChip(
                  label: currencyFormat.format(amount),
                  isSelected: _selectedAmount == amount && !_isCustomAmount,
                  onTap: () => _handleAmountSelect(amount),
                  isAmount: true,
                );
              },
            ),
            const SizedBox(height: 12),

            // Custom Amount Button
            OutlinedButton(
              key: const Key('customAmountButton'),
              onPressed: _handleCustomAmount,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: _isCustomAmount
                      ? AppColors.accentStart
                      : AppColors.backgroundTertiary,
                  width: 1.5,
                  style: BorderStyle
                      .solid, // Dashed border is hard in standard widget, solid is fine for now or use CustomPaint
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: _isCustomAmount
                    ? AppColors.accentStart.withOpacity(0.1)
                    : null,
              ),
              child: Text(
                '+ Custom amount',
                style: TextStyle(
                  color: _isCustomAmount
                      ? AppColors.accentStart
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            GradientButton(
              text: 'Save Expense',
              onPressed: canSave ? _saveExpense : null,
              isEnabled: canSave,
              isLoading: ref.watch(expenseListProvider).isLoading,
            ),

            const SizedBox(height: 16),

            // Scan Receipt Button
            TextButton.icon(
              onPressed: () {
                // TODO: Implement scan receipt
              },
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.textSecondary,
              ),
              label: const Text(
                'Scan receipt instead',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomAmountDialog extends StatefulWidget {
  @override
  State<_CustomAmountDialog> createState() => _CustomAmountDialogState();
}

class _CustomAmountDialogState extends State<_CustomAmountDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundSecondary,
      title: const Text('Enter Amount', style: AppTypography.titleLarge),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: AppTypography.headlineMedium,
        decoration: const InputDecoration(prefixText: 'RD\$ ', hintText: '0'),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            Navigator.pop(context, value);
          },
          child: const Text(
            'Done',
            style: TextStyle(color: AppColors.accentStart),
          ),
        ),
      ],
    );
  }
}
