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
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num).toDouble(),
      description: json['description']?.toString() ?? '',
      category: _parseCategory(json['category']),
      transactionDate: DateTime.parse(json['date'] ?? json['transaction_date']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      source: json['source']?.toString(),
      receiptUrl: json['receipt_url']?.toString(),
      ocrRawText: json['ocr_raw_text']?.toString(),
      ocrConfidence: json['ocr_confidence'] != null
          ? (json['ocr_confidence'] as num).toDouble()
          : null,
    );
  }

  static String _parseCategory(dynamic cat) {
    if (cat == null) return 'other';

    if (cat is List) {
      if (cat.isNotEmpty && cat[0] is Map) {
        return cat[0]['name']?.toString() ?? 'other';
      }
      return 'other';
    }

    if (cat is Map) {
      return cat['name']?.toString() ?? 'other';
    }

    return cat.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category_name': category,
      'date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'source': source,
      'receipt_url': receiptUrl,
      'ocr_raw_text': ocrRawText,
      'ocr_confidence': ocrConfidence,
    };
  }
}
