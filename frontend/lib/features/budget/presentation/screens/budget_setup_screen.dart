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

import 'dart:ui' as ui;

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentStart,
              onPrimary: Colors.white,
              surface: AppColors.backgroundSecondary,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
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
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(widget.budgetToEdit != null ? 'Edit Budget' : 'Set Budget'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundPrimary.withValues(alpha: 0.9),
                AppColors.backgroundSecondary.withValues(alpha: 0.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
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
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentStart.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentStart.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _emojiController.text,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _commonEmojis.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemBuilder: (context, index) {
                          final emoji = _commonEmojis[index];
                          final isSelected = _emojiController.text == emoji;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _emojiController.text = emoji),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 60 : 50,
                              height: isSelected ? 60 : 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentStart.withValues(
                                        alpha: 0.2,
                                      )
                                    : AppColors.backgroundSecondary.withValues(
                                        alpha: 0.3,
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.accentStart,
                                        width: 2,
                                      )
                                    : Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: isSelected ? 32 : 24,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Amount Input
              Text(
                'Budget Amount',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentStart.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextFormField(
                  key: const Key('budgetAmountField'),
                  controller: _amountController,
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 40,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixText: 'RD\$ ',
                    prefixStyle: AppTypography.displayLarge.copyWith(
                      fontSize: 40,
                      color: AppColors.accentStart,
                    ),
                    hintText: '0',
                    hintStyle: AppTypography.displayLarge.copyWith(
                      fontSize: 40,
                      color: AppColors.textSecondary.withValues(alpha: 0.2),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary.withValues(
                      alpha: 0.8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppColors.accentStart,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 32),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid amount';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Name Input
              Text(
                'Budget Name (Optional)',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., Monthly Groceries',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary.withValues(
                    alpha: 0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.accentStart),
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Period Selector
              Text(
                'Period',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 32),

              // Date Range
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starts',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectStartDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accentStart.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: AppColors.accentStart,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat.yMMMd().format(_startDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ends',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 16,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat.yMMMd().format(_endDate),
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
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
              ),

              const SizedBox(height: 48),

              // Submit Button
              GradientButton(
                key: const Key('saveBudgetButton'),
                text: widget.budgetToEdit != null
                    ? 'Update Budget'
                    : 'Create Budget',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
