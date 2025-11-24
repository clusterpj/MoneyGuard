import 'package:flutter/material.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';
import 'package:intl/intl.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;

  const ExpenseListItem({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'RD\$',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _getCategoryIcon(expense.category),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(expense.description),
      subtitle: Text(dateFormat.format(expense.transactionDate)),
      trailing: Text(
        currencyFormat.format(expense.amount),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'utilities':
        return Icons.lightbulb;
      default:
        return Icons.attach_money;
    }
  }
}
