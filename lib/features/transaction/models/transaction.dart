import 'package:vintage_ledger/core/enums/transaction_type.dart';

class TransactionModel {
  final int? id;
  final int walletId;
  final int categoryId;
  final TransactionType type;
  final int amount;
  final String? note;
  final int date;

  TransactionModel({
    this.id,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
  });

  TransactionModel copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    TransactionType? type,
    int? amount,
    String? note,
    int? date,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type.value,
      'amount': amount,
      'note': note,
      'date': date,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      categoryId: map['category_id'] as int,
      type: TransactionType.fromString(map['type'] as String),
      amount: map['amount'] is int
          ? map['amount']
          : int.parse(map['amount'].toString()),
      note: map['note'] as String?,
      date: map['date'] is int
          ? map['date']
          : int.parse(map['date'].toString()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          id == other.id &&
          walletId == other.walletId &&
          categoryId == other.categoryId &&
          type == other.type &&
          amount == other.amount &&
          date == other.date;

  @override
  int get hashCode => Object.hash(id, walletId, categoryId, type, amount, date);

  @override
  String toString() =>
      'TransactionModel(id: $id, type: ${type.value}, amount: $amount)';
}
