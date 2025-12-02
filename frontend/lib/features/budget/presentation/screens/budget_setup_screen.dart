import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/features/budget/presentation/providers/budget_provider.dart';
import 'package:moneyguard/shared/widgets/gradient_button.dart';
import 'package:moneyguard/shared/widgets/selectable_chip.dart';

class BudgetSetupScreen extends ConsumerStatefulWidget {
  final Budget? budgetToEdit;
  const BudgetSetupScreen({super.key, this.budgetToEdit});

  @override
  ConsumerState<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends ConsumerState<BudgetSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _emojiController;
  late String _period;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  final List<String> _commonEmojis = [
    '💰',
    '🏠',
    '🚗',
    '🍔',
    '✈️',
    '🎮',
    '🎓',
    '🏥',
  ];

  @override
  void initState() {
    super.initState();
    final budget = widget.budgetToEdit;
    _nameController = TextEditingController(text: budget?.name ?? '');
    _amountController = TextEditingController(
      text: budget?.amount.toString() ?? '',
    );
    _emojiController = TextEditingController(text: budget?.emoji ?? '💰');
    _period = budget?.period ?? 'monthly';
    _startDate = budget?.startDate ?? DateTime.now();
    _endDate = budget?.endDate ?? _calculateEndDate(DateTime.now(), 'monthly');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  DateTime _calculateEndDate(DateTime start, String period) {
    if (period == 'weekly') {
      return start.add(const Duration(days: 7));
    } else {
      // monthly
      return DateTime(
        start.year,
        start.month + 1,
        start.day,
      ).subtract(const Duration(days: 1));
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = _calculateEndDate(picked, _period);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      if (widget.budgetToEdit != null) {
        // Update existing budget
        final updatedBudget = widget.budgetToEdit!.copyWith(
          name: _nameController.text.isEmpty ? null : _nameController.text,
          amount: amount,
          period: _period,
          startDate: _startDate,
          endDate: _endDate,
          emoji: _emojiController.text,
        );
        await ref
            .read(budgetListProvider.notifier)
            .updateBudget(widget.budgetToEdit!.id, updatedBudget);
      } else {
        // Create new budget
        await ref
            .read(budgetListProvider.notifier)
            .addBudget(
              name: _nameController.text.isEmpty ? null : _nameController.text,
              amount: amount,
              period: _period,
              startDate: _startDate,
              endDate: _endDate,
              emoji: _emojiController.text,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget ${widget.budgetToEdit != null ? "updated" : "created"} successfully!',
            ),
            backgroundColor: AppColors.backgroundSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(widget.budgetToEdit != null ? 'Edit Budget' : 'Set Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji Picker
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentStart,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _emojiController.text,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _commonEmojis.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final emoji = _commonEmojis[index];
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _emojiController.text = emoji),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: _emojiController.text == emoji
                                    ? AppColors.accentStart.withOpacity(0.2)
                                    : AppColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: _emojiController.text == emoji
                                    ? Border.all(color: AppColors.accentStart)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Amount Input
              const Text('Budget Amount', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: AppTypography.displayLarge.copyWith(fontSize: 32),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: 'RD\$ ',
                  hintText: '0',
                  hintStyle: AppTypography.displayLarge.copyWith(
                    fontSize: 32,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 24),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Name Input
              const Text(
                'Budget Name (Optional)',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'e.g., Monthly Groceries',
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Period Selector
              const Text('Period', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SelectableChip(
                      label: 'Monthly',
                      isSelected: _period == 'monthly',
                      onTap: () {
                        setState(() {
                          _period = 'monthly';
                          _endDate = _calculateEndDate(_startDate, 'monthly');
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableChip(
                      label: 'Weekly',
                      isSelected: _period == 'weekly',
                      onTap: () {
                        setState(() {
                          _period = 'weekly';
                          _endDate = _calculateEndDate(_startDate, 'weekly');
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Starts', style: AppTypography.labelSmall),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(DateFormat.yMMMd().format(_startDate)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ends', style: AppTypography.labelSmall),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event_busy,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMMMd().format(_endDate),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Submit Button
              GradientButton(
                text: widget.budgetToEdit != null
                    ? 'Update Budget'
                    : 'Create Budget',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
