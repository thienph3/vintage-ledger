import 'package:vintage_ledger/core/enums/transaction_type.dart';

enum Frequency { daily, weekly, monthly }

extension FrequencyX on Frequency {
  String get value => name;

  String l10nKey() => switch (this) {
    Frequency.daily => 'daily',
    Frequency.weekly => 'weekly',
    Frequency.monthly => 'monthly',
  };

  static Frequency fromString(String s) => switch (s) {
    'daily' => Frequency.daily,
    'weekly' => Frequency.weekly,
    _ => Frequency.monthly,
  };
}

class RecurringRule {
  final String? id;
  final int amount;
  final String categoryId;
  final String walletId;
  final TransactionType type;
  final Frequency frequency;
  final String? note;
  final int nextRunAt;
  final bool enabled;
  final String? linkedDebtId;
  final String? linkedGoalId;

  RecurringRule({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    this.type = TransactionType.expense,
    this.frequency = Frequency.monthly,
    this.note,
    required this.nextRunAt,
    this.enabled = true,
    this.linkedDebtId,
    this.linkedGoalId,
  });

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'category_id': categoryId,
    'wallet_id': walletId,
    'type': type.value,
    'frequency': frequency.value,
    'note': note,
    'next_run_at': nextRunAt,
    'enabled': enabled,
    'linked_debt_id': linkedDebtId,
    'linked_goal_id': linkedGoalId,
  };

  factory RecurringRule.fromMap(String id, Map<String, dynamic> map) => RecurringRule(
    id: id,
    amount: map['amount'] ?? 0,
    categoryId: map['category_id'] ?? '',
    walletId: map['wallet_id'] ?? '',
    type: TransactionType.fromString(map['type'] ?? 'expense'),
    frequency: FrequencyX.fromString(map['frequency'] ?? 'monthly'),
    note: map['note'],
    nextRunAt: map['next_run_at'] ?? 0,
    enabled: map['enabled'] ?? true,
    linkedDebtId: map['linked_debt_id'],
    linkedGoalId: map['linked_goal_id'],
  );

  /// Returns an error message if both linkedDebtId and linkedGoalId are non-null.
  /// Returns null if validation passes.
  String? validateLinkedEntity() {
    if (linkedDebtId != null && linkedGoalId != null) {
      return 'Không thể liên kết cả khoản nợ và mục tiêu cùng lúc. Vui lòng chọn một trong hai.';
    }
    return null;
  }
}
