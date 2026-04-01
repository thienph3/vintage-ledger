class TransactionItemModel {
  final int amount;
  final String? categoryId;
  final String? note;

  TransactionItemModel({required this.amount, this.categoryId, this.note});

  TransactionItemModel copyWith({int? amount, String? categoryId, String? note}) {
    return TransactionItemModel(
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'category_id': categoryId,
    'note': note,
  };

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) => TransactionItemModel(
    amount: map['amount'] is int ? map['amount'] : int.parse(map['amount'].toString()),
    categoryId: map['category_id']?.toString(),
    note: map['note'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionItemModel && amount == other.amount && categoryId == other.categoryId;

  @override
  int get hashCode => Object.hash(amount, categoryId);
}
