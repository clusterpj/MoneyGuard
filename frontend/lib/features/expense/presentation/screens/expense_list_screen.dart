import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';
import 'package:moneyguard/features/expense/presentation/screens/add_expense_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => RefreshIndicator(
          onRefresh: () => ref.read(expenseListProvider.notifier).refresh(),
          child: expenses.isEmpty
              ? const Center(child: Text('No expenses found'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Dismissible(
                      key: Key(expense.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: const Text(
                              'Are you sure you want to delete this expense?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        ref
                            .read(expenseListProvider.notifier)
                            .deleteExpense(expense.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense deleted')),
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            expense.category.isNotEmpty
                                ? expense.category[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(expense.description),
                        subtitle: Text(
                          DateFormat.yMMMd().format(expense.transactionDate),
                        ),
                        trailing: Text(
                          '\$${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddExpenseScreen(expenseToEdit: expense),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Last 30 Days'),
                onTap: () {
                  final now = DateTime.now();
                  ref
                      .read(expenseListProvider.notifier)
                      .updateFilters(
                        ExpenseFilters(
                          startDate: now.subtract(const Duration(days: 30)),
                          endDate: now,
                        ),
                      );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('All Time'),
                onTap: () {
                  ref
                      .read(expenseListProvider.notifier)
                      .updateFilters(ExpenseFilters());
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
