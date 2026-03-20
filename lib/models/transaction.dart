class TransactionModel {

  final int? id;
  final int walletId;
  final int categoryId;
  final String type;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
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
      type: map['type'] as String,
      amount: map['amount'] is int
          ? map['amount']
          : int.parse(map['amount'].toString()),
      note: map['note'] as String?,
      date: map['date'] is int
          ? map['date']
          : int.parse(map['date'].toString()),
    );
  }

}