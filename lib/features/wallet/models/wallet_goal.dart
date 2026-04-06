class WalletGoal {
  final String? id;
  final String name;
  final int targetAmount;
  final int savedAmount;
  final int? deadline;
  final String? emoji;
  final int createdAt;

  WalletGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    this.emoji,
    this.createdAt = 0,
  });

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
  int get remaining => (targetAmount - savedAmount).clamp(0, targetAmount);
  bool get isReached => savedAmount >= targetAmount;

  int? get daysLeft {
    if (deadline == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((deadline! - now) / 86400000).ceil();
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'deadline': deadline,
    'emoji': emoji,
    'created_at': createdAt,
  };

  factory WalletGoal.fromMap(String id, Map<String, dynamic> data) => WalletGoal(
    id: id,
    name: data['name'] ?? '',
    targetAmount: data['target_amount'] ?? 0,
    savedAmount: data['saved_amount'] ?? 0,
    deadline: data['deadline'],
    emoji: data['emoji'],
    createdAt: data['created_at'] ?? 0,
  );
}
