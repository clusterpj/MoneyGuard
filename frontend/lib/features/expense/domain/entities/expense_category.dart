import 'package:flutter/material.dart';
import 'package:moneyguard/core/theme/app_colors.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  static const List<ExpenseCategory> defaults = [
    ExpenseCategory(
      id: 'food',
      name: 'Food',
      emoji: '🍔',
      color: Color(0xFFFF6B6B),
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transport',
      emoji: '🚗',
      color: Color(0xFF4ECDC4),
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      emoji: '🛍️',
      color: Color(0xFFA78BFA),
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Fun',
      emoji: '🎬',
      color: Color(0xFFFBBF24),
    ),
    ExpenseCategory(
      id: 'bills',
      name: 'Bills',
      emoji: '📄',
      color: Color(0xFF60A5FA),
    ),
    ExpenseCategory(
      id: 'health',
      name: 'Health',
      emoji: '💊',
      color: Color(0xFF34D399),
    ),
  ];

  static ExpenseCategory fromId(String id) {
    return defaults.firstWhere(
      (c) => c.id == id.toLowerCase(),
      orElse: () => ExpenseCategory(
        id: 'other',
        name: 'Other',
        emoji: '📝',
        color: AppColors.textSecondary,
      ),
    );
  }
}
