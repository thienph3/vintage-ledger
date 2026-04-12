enum DebtType { 
  lend, 
  borrow;
  
  String get displayName {
    switch (this) {
      case DebtType.lend:
        return 'Cho vay';
      case DebtType.borrow:
        return 'Vay mượn';
    }
  }
  
  String get actionName {
    switch (this) {
      case DebtType.lend:
        return 'Cho vay';
      case DebtType.borrow:
        return 'Vay tiền';
    }
  }
}

enum DebtStatus { 
  active, 
  completed, 
  cancelled;
  
  String get displayName {
    switch (this) {
      case DebtStatus.active:
        return 'Đang hoạt động';
      case DebtStatus.completed:
        return 'Đã hoàn thành';
      case DebtStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

class Debt {
  final String id;
  final String accountId;
  final DebtType type;
  final String partyName;
  final String? partyContact;
  final int totalAmount;
  final int paidAmount;
  final DateTime? dueDate;
  final double? interestRate;
  final String? description;
  final String? walletId;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? linkedDebtId;
  final String? linkedAccountId;
  final String? partyUserId;

  const Debt({
    required this.id,
    required this.accountId,
    required this.type,
    required this.partyName,
    this.partyContact,
    required this.totalAmount,
    required this.paidAmount,
    this.dueDate,
    this.interestRate,
    this.description,
    this.walletId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.linkedDebtId,
    this.linkedAccountId,
    this.partyUserId,
  });

  // Computed properties
  int get remainingAmount => totalAmount - paidAmount;
  
  bool get isCompleted => status == DebtStatus.completed || remainingAmount <= 0;
  
  double get progressPercentage => totalAmount > 0 ? paidAmount / totalAmount : 0.0;
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }
  
  int get daysUntilDue {
    if (dueDate == null) return 0;
    return dueDate!.difference(DateTime.now()).inDays;
  }
  
  bool get isLinked => linkedDebtId != null;

  bool get isLent => type == DebtType.lend;
  bool get isBorrowed => type == DebtType.borrow;
  
  String get displayTitle {
    final action = type == DebtType.lend ? 'Cho vay' : 'Vay từ';
    return '$action $partyName';
  }

  // Factory constructors
  factory Debt.fromMap(String id, Map<String, dynamic> data) {
    return Debt(
      id: id,
      accountId: data['account_id'] ?? '',
      type: DebtType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => DebtType.borrow,
      ),
      partyName: data['party_name'] ?? '',
      partyContact: data['party_contact'],
      totalAmount: data['total_amount'] ?? 0,
      paidAmount: data['paid_amount'] ?? 0,
      dueDate: data['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['due_date'])
          : null,
      interestRate: data['interest_rate']?.toDouble(),
      description: data['description'],
      walletId: data['wallet_id'],
      status: DebtStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DebtStatus.active,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at'] ?? 0),
      linkedDebtId: data['linked_debt_id'],
      linkedAccountId: data['linked_account_id'],
      partyUserId: data['party_user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'type': type.name,
      'party_name': partyName,
      if (partyContact != null) 'party_contact': partyContact,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      if (dueDate != null) 'due_date': dueDate!.millisecondsSinceEpoch,
      if (interestRate != null) 'interest_rate': interestRate,
      if (description != null) 'description': description,
      if (walletId != null) 'wallet_id': walletId,
      'status': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      if (linkedDebtId != null) 'linked_debt_id': linkedDebtId,
      if (linkedAccountId != null) 'linked_account_id': linkedAccountId,
      if (partyUserId != null) 'party_user_id': partyUserId,
    };
  }

  Debt copyWith({
    String? id,
    String? accountId,
    DebtType? type,
    String? partyName,
    String? partyContact,
    int? totalAmount,
    int? paidAmount,
    DateTime? dueDate,
    double? interestRate,
    String? description,
    String? walletId,
    DebtStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedDebtId,
    String? linkedAccountId,
    String? partyUserId,
  }) {
    return Debt(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      partyName: partyName ?? this.partyName,
      partyContact: partyContact ?? this.partyContact,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      interestRate: interestRate ?? this.interestRate,
      description: description ?? this.description,
      walletId: walletId ?? this.walletId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedDebtId: linkedDebtId ?? this.linkedDebtId,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      partyUserId: partyUserId ?? this.partyUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Debt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Debt(id: $id, type: $type, party: $partyName, amount: $totalAmount, paid: $paidAmount, isLinked: $isLinked)';
  }
}