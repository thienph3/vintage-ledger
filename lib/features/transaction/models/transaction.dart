import 'package:vintage_ledger/core/enums/transaction_type.dart';

class TransactionModel {
  final int? id;
  final int walletId;
  final int categoryId;
  final TransactionType type;
  final int amount;
  final String? note;
  final int date;
  final String accountId;
  final int isSynced;
  final String? remoteId;
  final String? createdBy;

  TransactionModel({
    this.id,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    this.accountId = 'local',
    this.isSynced = 1,
    this.remoteId,
    this.createdBy,
  });

  TransactionModel copyWith({
    int? id, int? walletId, int? categoryId, TransactionType? type,
    int? amount, String? note, int? date, String? accountId,
    int? isSynced, String? remoteId, String? createdBy,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'wallet_id': walletId,
    'category_id': categoryId,
    'type': type.value,
    'amount': amount,
    'note': note,
    'date': date,
    'account_id': accountId,
    'is_synced': isSynced,
    'remote_id': remoteId,
    'created_by': createdBy,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) => TransactionModel(
    id: map['id'] as int?,
    walletId: map['wallet_id'] as int,
    categoryId: map['category_id'] as int,
    type: TransactionType.fromString(map['type'] as String),
    amount: map['amount'] is int ? map['amount'] : int.parse(map['amount'].toString()),
    note: map['note'] as String?,
    date: map['date'] is int ? map['date'] : int.parse(map['date'].toString()),
    accountId: map['account_id'] ?? 'local',
    isSynced: map['is_synced'] ?? 1,
    remoteId: map['remote_id'],
    createdBy: map['created_by'],
  );

  bool get isDirty => isSynced == 0;

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
