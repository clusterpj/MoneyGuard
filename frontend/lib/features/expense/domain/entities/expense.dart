class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime transactionDate;
  final DateTime createdAt;
  final String? source;
  final String? receiptUrl;
  final String? ocrRawText;
  final double? ocrConfidence;

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.transactionDate,
    required this.createdAt,
    this.source,
    this.receiptUrl,
    this.ocrRawText,
    this.ocrConfidence,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      category: json['category'] != null
          ? (json['category'] is Map
                ? json['category']['name']
                : json['category'])
          : 'other',
      transactionDate: DateTime.parse(json['transaction_date'] ?? json['date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      source: json['source'],
      receiptUrl: json['receipt_url'],
      ocrRawText: json['ocr_raw_text'],
      ocrConfidence: json['ocr_confidence'] != null
          ? (json['ocr_confidence'] as num).toDouble()
          : null,
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
      'source': source,
      'receipt_url': receiptUrl,
      'ocr_raw_text': ocrRawText,
      'ocr_confidence': ocrConfidence,
    };
  }
}
