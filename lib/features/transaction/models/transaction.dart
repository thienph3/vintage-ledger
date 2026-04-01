import 'package:vintage_ledger/core/enums/transaction_type.dart';

class TransactionModel {
  final String? id;
  final String walletId;
  final String categoryId;
  final TransactionType type;
  final int amount;
  final String? note;
  final int date;
  final String? createdBy;

  TransactionModel({
    this.id,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    this.createdBy,
  });

  TransactionModel copyWith({
    String? id, String? walletId, String? categoryId, TransactionType? type,
    int? amount, String? note, int? date, String? createdBy,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel && id == other.id && walletId == other.walletId &&
          categoryId == other.categoryId && type == other.type &&
          amount == other.amount && date == other.date;

  @override
  int get hashCode => Object.hash(id, walletId, categoryId, type, amount, date);

  @override
  String toString() => 'TransactionModel(id: $id, type: ${type.value}, amount: $amount)';
}
