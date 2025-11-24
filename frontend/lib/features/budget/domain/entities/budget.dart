class Budget {
  final String id;
  final double totalAmount;
  final double spentAmount;
  final double safeToSpend;
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;

  Budget({
    required this.id,
    required this.totalAmount,
    required this.spentAmount,
    required this.safeToSpend,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
  });

  double get remainingAmount => totalAmount - spentAmount;
  double get percentageSpent => (spentAmount / totalAmount) * 100;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      safeToSpend: (json['safe_to_spend'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      daysRemaining: json['days_remaining'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'spent_amount': spentAmount,
      'safe_to_spend': safeToSpend,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'days_remaining': daysRemaining,
    };
  }
}
