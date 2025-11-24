class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime transactionDate;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.transactionDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
