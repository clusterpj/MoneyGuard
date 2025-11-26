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
    final totalAmount = (json['amount'] as num).toDouble();
    final spentAmount = (json['spent_amount'] as num?)?.toDouble() ?? 0.0;
    final startDate = DateTime.parse(json['start_date']);
    final endDate = DateTime.parse(json['end_date']);
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;

    // Calculate safe to spend based on days remaining
    final daysInPeriod = endDate.difference(startDate).inDays;
    final dailyBudget = totalAmount / daysInPeriod;
    final safeToSpend = dailyBudget * daysRemaining;

    return Budget(
      id: json['id'],
      totalAmount: totalAmount,
      spentAmount: spentAmount,
      safeToSpend: safeToSpend > 0 ? safeToSpend : 0,
      startDate: startDate,
      endDate: endDate,
      daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
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
