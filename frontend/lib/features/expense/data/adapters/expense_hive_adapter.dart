import 'package:hive/hive.dart';
import 'package:moneyguard/features/expense/domain/entities/expense.dart';

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 1;

  @override
  Expense read(BinaryReader reader) {
    return Expense(
      id: reader.readString(),
      amount: reader.readDouble(),
      description: reader.readString(),
      category: reader.readString(),
      transactionDate: DateTime.parse(reader.readString()),
      createdAt: DateTime.parse(reader.readString()),
      source: reader.readString(),
      receiptUrl: reader.readString(),
      ocrRawText: reader.readString(),
      ocrConfidence: reader.readDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.description);
    writer.writeString(obj.category);
    writer.writeString(obj.transactionDate.toIso8601String());
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.source ?? '');
    writer.writeString(obj.receiptUrl ?? '');
    writer.writeString(obj.ocrRawText ?? '');
    writer.writeDouble(obj.ocrConfidence ?? 0.0);
  }
}