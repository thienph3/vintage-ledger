enum BudgetPeriod {
  weekly,
  monthly;

  String get l10nKey {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.monthly:
        return 'monthly';
    }
  }
}

class Budget {
  final String? id;
  final String categoryId;
  final int amountLimit;
  final BudgetPeriod period;

  Budget({
    this.id,
    required this.categoryId,
    required this.amountLimit,
    this.period = BudgetPeriod.monthly,
  });

  Budget copyWith({String? id, String? categoryId, int? amountLimit, BudgetPeriod? period}) {
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
