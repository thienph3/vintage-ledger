enum DebtType {
  lend,
  borrow;

  static DebtType fromString(String value) =>
      DebtType.values.firstWhere((e) => e.name == value, orElse: () => DebtType.lend);
}

class Debt {
  final String? id;
  final DebtType type;
  final String partyName;
  final String? partyUserId;
  final int totalAmount;
  final int paidAmount;
  final String? walletId;
  final String? note;
  final int? dueDate;
  final int createdAt;
  final bool settled;

  Debt({
    this.id,
    required this.type,
    required this.partyName,
    this.partyUserId,
    required this.totalAmount,
    this.paidAmount = 0,
    this.walletId,
    this.note,
    this.dueDate,
    this.createdAt = 0,
    this.settled = false,
  });

  int get remaining => (totalAmount - paidAmount).clamp(0, totalAmount);
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0;
  bool get isLend => type == DebtType.lend;
  bool get isBorrow => type == DebtType.borrow;

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'party_name': partyName,
    'party_user_id': partyUserId,
    'total_amount': totalAmount,
    'paid_amount': paidAmount,
    'wallet_id': walletId,
    'note': note,
    'due_date': dueDate,
    'created_at': createdAt,
    'settled': settled,
  };

  factory Debt.fromMap(String id, Map<String, dynamic> data) => Debt(
    id: id,
    type: DebtType.fromString(data['type'] ?? 'lend'),
    partyName: data['party_name'] ?? '',
    partyUserId: data['party_user_id'],
    totalAmount: data['total_amount'] ?? 0,
    paidAmount: data['paid_amount'] ?? 0,
    walletId: data['wallet_id'],
    note: data['note'],
    dueDate: data['due_date'],
    createdAt: data['created_at'] ?? 0,
    settled: data['settled'] ?? false,
  );
}
