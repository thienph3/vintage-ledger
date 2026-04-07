class GoalContribution {
  final String id;
  final String goalId;
  final int amount;
  final DateTime date;
  final String? note;
  final String? transactionId;
  final String createdBy;
  final DateTime createdAt;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    this.transactionId,
    required this.createdBy,
    required this.createdAt,
  });

  // Computed properties
  bool get isLinkedToTransaction => transactionId != null;
  
  bool get isWithdrawal => amount < 0;
  
  bool get isContribution => amount > 0;
  
  int get absoluteAmount => amount.abs();
  
  String get displayNote => note ?? (isContribution ? 'Tiết kiệm' : 'Rút tiền');
  
  String get actionType => isContribution ? 'Nạp vào' : 'Rút từ';

  // Factory constructors
  factory GoalContribution.fromMap(String id, Map<String, dynamic> data) {
    return GoalContribution(
      id: id,
      goalId: data['goal_id'] ?? '',
      amount: data['amount'] ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      note: data['note'],
      transactionId: data['transaction_id'],
      createdBy: data['created_by'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': goalId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      if (note != null) 'note': note,
      if (transactionId != null) 'transaction_id': transactionId,
      'created_by': createdBy,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  GoalContribution copyWith({
    String? id,
    String? goalId,
    int? amount,
    DateTime? date,
    String? note,
    String? transactionId,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return GoalContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      transactionId: transactionId ?? this.transactionId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalContribution && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GoalContribution(id: $id, goalId: $goalId, amount: $amount, date: $date)';
  }
}

/// Combined model for goal with its contributions
class GoalWithContributions {
  final GoalV2 goal;
  final List<GoalContribution> contributions;

  const GoalWithContributions({
    required this.goal,
    required this.contributions,
  });

  // Computed properties
  int get totalContributed => contributions
      .where((c) => c.isContribution)
      .fold(0, (sum, c) => sum + c.amount);
  
  int get totalWithdrawn => contributions
      .where((c) => c.isWithdrawal)
      .fold(0, (sum, c) => sum + c.absoluteAmount);
  
  List<GoalContribution> get sortedContributions => 
      List.from(contributions)..sort((a, b) => b.date.compareTo(a.date));
  
  GoalContribution? get lastContribution => 
      contributions.isEmpty ? null : sortedContributions.first;
  
  bool get hasContributions => contributions.isNotEmpty;
  
  int get contributionCount => contributions.length;
  
  List<GoalContribution> get recentContributions => 
      sortedContributions.take(5).toList();

  GoalWithContributions copyWith({
    GoalV2? goal,
    List<GoalContribution>? contributions,
  }) {
    return GoalWithContributions(
      goal: goal ?? this.goal,
      contributions: contributions ?? this.contributions,
    );
  }
}