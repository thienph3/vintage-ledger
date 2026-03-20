class TransactionItemModel {
  final int? id;
  final int transactionId; // liên kết với TransactionModel
  final int amount;
  final int? categoryId; // nếu null → fallback dùng category của parent
  final String? note;

  TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.amount,
    this.categoryId,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'amount': amount,
      'category_id': categoryId,
      'note': note,
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int,
      amount: map['amount'] is int
          ? map['amount']
          : int.parse(map['amount'].toString()),
      categoryId: map['category_id'] as int?,
      note: map['note'] as String?,
    );
  }
}