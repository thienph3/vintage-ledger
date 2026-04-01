class Budget {
  final String? id;
  final String categoryId;
  final int amountLimit;
  final String period; // 'monthly'

  Budget({
    this.id,
    required this.categoryId,
    required this.amountLimit,
    this.period = 'monthly',
  });

  Budget copyWith({String? id, String? categoryId, int? amountLimit, String? period}) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      period: period ?? this.period,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget && id == other.id && categoryId == other.categoryId &&
          amountLimit == other.amountLimit;

  @override
  int get hashCode => Object.hash(id, categoryId, amountLimit);
}
