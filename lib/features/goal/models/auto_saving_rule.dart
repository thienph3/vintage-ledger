enum RecurrenceType { 
  daily,
  weekly,
  monthly;
  
  String get displayName {
    switch (this) {
      case RecurrenceType.daily:
        return 'Hàng ngày';
      case RecurrenceType.weekly:
        return 'Hàng tuần';
      case RecurrenceType.monthly:
        return 'Hàng tháng';
    }
  }
}

class AutoSavingRule {
  final String id;
  final String goalId;
  final int amount;
  final RecurrenceType frequency;
  final DateTime nextRunDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AutoSavingRule({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.frequency,
    required this.nextRunDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  bool get isPaused => !isActive;
  
  bool get isDue => DateTime.now().isAfter(nextRunDate) && isActive;
  
  int get daysUntilNext => nextRunDate.difference(DateTime.now()).inDays;
  
  DateTime calculateNextRunDate() {
    final now = DateTime.now();
    switch (frequency) {
      case RecurrenceType.daily:
        return DateTime(now.year, now.month, now.day + 1);
      case RecurrenceType.weekly:
        return DateTime(now.year, now.month, now.day + 7);
      case RecurrenceType.monthly:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }

  // Factory constructors
  factory AutoSavingRule.fromMap(String id, Map<String, dynamic> data) {
    return AutoSavingRule(
      id: id,
      goalId: data['goal_id'] ?? '',
      amount: data['amount'] ?? 0,
      frequency: RecurrenceType.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => RecurrenceType.monthly,
      ),
      nextRunDate: DateTime.fromMillisecondsSinceEpoch(data['next_run_date'] ?? 0),
      isActive: data['is_active'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'amount': amount,
      'frequency': frequency.name,
      'next_run_date': nextRunDate.millisecondsSinceEpoch,
      'is_active': isActive,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  AutoSavingRule copyWith({
    String? id,
    String? goalId,
    int? amount,
    RecurrenceType? frequency,
    DateTime? nextRunDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AutoSavingRule(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AutoSavingRule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AutoSavingRule(id: $id, goalId: $goalId, amount: $amount, frequency: $frequency, isActive: $isActive)';
  }
}
