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
  final String? toWalletId;
  final String? toAccountId;
  final String? linkedTransactionId;
  final String? fundingWalletId;
  final String? fundingAccountId;
  final String? fundingTransferId;

  TransactionModel({
    this.id,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    this.createdBy,
    this.toWalletId,
    this.toAccountId,
    this.linkedTransactionId,
    this.fundingWalletId,
    this.fundingAccountId,
    this.fundingTransferId,
  });

  TransactionModel copyWith({
    String? id, String? walletId, String? categoryId, TransactionType? type,
    int? amount, String? note, int? date, String? createdBy,
    String? toWalletId, String? toAccountId, String? linkedTransactionId,
    String? fundingWalletId, String? fundingAccountId, String? fundingTransferId,
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
      toWalletId: toWalletId ?? this.toWalletId,
      toAccountId: toAccountId ?? this.toAccountId,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      fundingWalletId: fundingWalletId ?? this.fundingWalletId,
      fundingAccountId: fundingAccountId ?? this.fundingAccountId,
      fundingTransferId: fundingTransferId ?? this.fundingTransferId,
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
