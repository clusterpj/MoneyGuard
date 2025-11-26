import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/features/budget/presentation/providers/budget_provider.dart';
import 'package:moneyguard/features/budget/presentation/screens/budget_setup_screen.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: budgetsAsync.when(
        data: (budgets) => RefreshIndicator(
          onRefresh: () => ref.read(budgetListProvider.notifier).refresh(),
          child: budgets.isEmpty
              ? const Center(child: Text('No budgets found'))
              : ListView.builder(
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    final isActive =
                        DateTime.now().isBefore(budget.endDate) &&
                        DateTime.now().isAfter(budget.startDate);

                    return Dismissible(
                      key: Key(budget.id),
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
                            title: const Text('Delete Budget'),
                            content: const Text(
                              'Are you sure you want to delete this budget?',
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
                            .read(budgetListProvider.notifier)
                            .deleteBudget(budget.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Budget deleted')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Colors.green
                                : Colors.grey,
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(budget.name ?? '${budget.period} Budget'),
                          subtitle: Text(
                            '${DateFormat.yMMMd().format(budget.startDate)} - ${DateFormat.yMMMd().format(budget.endDate)}\n'
                            '${isActive ? "Active" : "Ended"}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${budget.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (budget.spent != null)
                                Text(
                                  'Spent: \$${budget.spent!.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BudgetSetupScreen(budgetToEdit: budget),
                              ),
                            );
                          },
                        ),
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
            MaterialPageRoute(builder: (context) => const BudgetSetupScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
