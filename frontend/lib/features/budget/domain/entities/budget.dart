class Budget {
  final String id;
  final String? name;
  final String emoji;
  final double amount;
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final double? spent;
  final double? remaining;
  final double? percentageUsed;

  Budget({
    required this.id,
    this.name,
    this.emoji = '💰',
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.spent,
    this.remaining,
    this.percentageUsed,
  });

  double get calculatedRemaining => (remaining ?? amount - (spent ?? 0));
  double get calculatedPercentageUsed =>
      (percentageUsed ?? ((spent ?? 0) / amount * 100));
  int get daysRemaining =>
      endDate.difference(DateTime.now()).inDays.clamp(0, 999);

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'] ?? '💰',
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] ?? 'monthly',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      categoryId: json['category_id'],
      spent: json['spent'] != null ? (json['spent'] as num).toDouble() : null,
      remaining: json['remaining'] != null
          ? (json['remaining'] as num).toDouble()
          : null,
      percentageUsed: json['percentage_used'] != null
          ? (json['percentage_used'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'amount': amount,
      'period': period,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'category_id': categoryId,
      if (spent != null) 'spent': spent,
      if (remaining != null) 'remaining': remaining,
      if (percentageUsed != null) 'percentage_used': percentageUsed,
    };
  }

  Budget copyWith({
    String? id,
    String? name,
    String? emoji,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    double? spent,
    double? remaining,
    double? percentageUsed,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      percentageUsed: percentageUsed ?? this.percentageUsed,
    );
  }
}
