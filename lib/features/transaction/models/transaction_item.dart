class TransactionItemModel {
  final int? id;
  final int transactionId;
  final int amount;
  final int? categoryId;
  final String? note;

  TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.amount,
    this.categoryId,
    this.note,
  });

  TransactionItemModel copyWith({
    int? id,
    int? transactionId,
    int? amount,
    int? categoryId,
    String? note,
  }) {
    return TransactionItemModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
    );
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItemModel &&
          id == other.id &&
          transactionId == other.transactionId &&
          amount == other.amount &&
          categoryId == other.categoryId;

  @override
  int get hashCode => Object.hash(id, transactionId, amount, categoryId);

  @override
  String toString() =>
      'TransactionItemModel(id: $id, transactionId: $transactionId, amount: $amount)';
}
