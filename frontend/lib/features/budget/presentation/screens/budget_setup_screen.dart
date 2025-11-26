import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moneyguard/features/budget/domain/entities/budget.dart';
import 'package:moneyguard/features/budget/presentation/providers/budget_provider.dart';

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
  late String _period;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final budget = widget.budgetToEdit;
    _nameController = TextEditingController(text: budget?.name ?? '');
    _amountController = TextEditingController(
      text: budget?.amount.toString() ?? '',
    );
    _period = budget?.period ?? 'monthly';
    _startDate = budget?.startDate ?? DateTime.now();
    _endDate = budget?.endDate ?? _calculateEndDate(DateTime.now(), 'monthly');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
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
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Budget ${widget.budgetToEdit != null ? "updated" : "created"} successfully!',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
      appBar: AppBar(
        title: Text(widget.budgetToEdit != null ? 'Edit Budget' : 'Set Budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.budgetToEdit != null
                    ? 'Update Your Budget'
                    : 'Set Your Budget',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Track your spending and get smart recommendations.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Budget Name (Optional)',
                  hintText: 'e.g., Monthly Budget',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Budget Amount',
                  prefixText: '\$ ',
                  hintText: '1000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _period,
                decoration: const InputDecoration(labelText: 'Budget Period'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _period = value;
                      _endDate = _calculateEndDate(_startDate, value);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'End Date: ${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.budgetToEdit != null
                            ? 'Update Budget'
                            : 'Create Budget',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
