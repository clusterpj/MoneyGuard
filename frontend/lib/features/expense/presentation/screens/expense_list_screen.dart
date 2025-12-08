import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:moneyguard/features/expense/domain/entities/expense_category.dart';
import 'package:moneyguard/features/expense/presentation/providers/expense_provider.dart';
import 'package:moneyguard/features/expense/presentation/screens/add_expense_screen.dart';
import 'package:moneyguard/features/expense/presentation/widgets/expense_list_item.dart';
import 'package:moneyguard/features/expense/presentation/screens/import_screen.dart';
import 'package:moneyguard/shared/widgets/selectable_chip.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String? _selectedCategoryId;

  Map<DateTime, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final Map<DateTime, List<Expense>> grouped = {};
    for (var expense in expenses) {
      final date = DateTime(
        expense.transactionDate.year,
        expense.transactionDate.month,
        expense.transactionDate.day,
      );
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(expense);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('All Expenses', style: AppTypography.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportScreen()),
              );
            },
          ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) {
          // Filter expenses
          final filteredExpenses = _selectedCategoryId == null
              ? expenses
              : expenses
                    .where((e) => e.category == _selectedCategoryId)
                    .toList(); // Note: e.category is essentially categoryId in our new model

          // Group expenses
          final groupedExpenses = _groupExpensesByDate(filteredExpenses);
          final sortedDates = groupedExpenses.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // Category Filters
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: ExpenseCategory.defaults.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return SelectableChip(
                        label: 'All',
                        isSelected: _selectedCategoryId == null,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      );
                    }
                    final category = ExpenseCategory.defaults[index - 1];
                    return SelectableChip(
                      label: category.name,
                      emoji: category.emoji,
                      isSelected: _selectedCategoryId == category.id,
                      onTap: () =>
                          setState(() => _selectedCategoryId = category.id),
                    );
                  },
                ),
              ),

              // Expense List
              Expanded(
                child: filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses found',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(expenseListProvider.notifier).refresh(),
                        color: AppColors.accentStart,
                        backgroundColor: AppColors.backgroundSecondary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            final date = sortedDates[index];
                            final dayExpenses = groupedExpenses[date]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    _formatDateHeader(date),
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ...dayExpenses.map(
                                  (expense) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ExpenseListItem(
                                      expense: expense,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddExpenseScreen(
                                                  expenseToEdit: expense,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        backgroundColor: AppColors.accentStart,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat.yMMMd().format(date);
  }
}
