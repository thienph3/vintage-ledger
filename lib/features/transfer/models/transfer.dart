enum TransferType {
  internal,     // Giữa các ví trong cùng tài khoản
  funding,      // Cá nhân → Ví gia đình  
  crossAccount; // Giữa các tài khoản khác nhau
  
  String get displayName {
    switch (this) {
      case TransferType.internal:
        return 'Chuyển nội bộ';
      case TransferType.funding:
        return 'Nạp gia đình';
      case TransferType.crossAccount:
        return 'Chuyển liên tài khoản';
    }
  }
}

enum TransferStatus { 
  pending, 
  completed, 
  failed;
  
  String get displayName {
    switch (this) {
      case TransferStatus.pending:
        return 'Đang xử lý';
      case TransferStatus.completed:
        return 'Hoàn thành';
      case TransferStatus.failed:
        return 'Thất bại';
    }
  }
}

class Transfer {
  final String id;
  final TransferType type;
  final String sourceWalletId;
  final String sourceAccountId;
  final String destWalletId;
  final String? destAccountId;
  final int amount;
  final String? note;
  final DateTime date;
  final String createdBy;
  final TransferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transfer({
    required this.id,
    required this.type,
    required this.sourceWalletId,
    required this.sourceAccountId,
    required this.destWalletId,
    this.destAccountId,
    required this.amount,
    this.note,
    required this.date,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  bool get isCrossAccount => destAccountId != null && destAccountId != sourceAccountId;
  
  bool get isFamilyFunding => type == TransferType.funding;
  
  bool get isInternal => type == TransferType.internal;
  
  bool get isCompleted => status == TransferStatus.completed;
  
  bool get isPending => status == TransferStatus.pending;
  
  bool get isFailed => status == TransferStatus.failed;
  
  String get displayNote => note ?? 'Chuyển tiền';

  // Factory constructors
  factory Transfer.fromMap(String id, Map<String, dynamic> data) {
    return Transfer(
      id: id,
      type: TransferType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransferType.internal,
      ),
      sourceWalletId: data['source_wallet_id'] ?? '',
      sourceAccountId: data['source_account_id'] ?? '',
      destWalletId: data['dest_wallet_id'] ?? '',
      destAccountId: data['dest_account_id'],
      amount: data['amount'] ?? 0,
      note: data['note'],
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      createdBy: data['created_by'] ?? '',
      status: TransferStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransferStatus.completed,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'source_wallet_id': sourceWalletId,
      'source_account_id': sourceAccountId,
      'dest_wallet_id': destWalletId,
      if (destAccountId != null) 'dest_account_id': destAccountId,
      'amount': amount,
      if (note != null) 'note': note,
      'date': date.millisecondsSinceEpoch,
      'created_by': createdBy,
      'status': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Transfer copyWith({
    String? id,
    TransferType? type,
    String? sourceWalletId,
    String? sourceAccountId,
    String? destWalletId,
    String? destAccountId,
    int? amount,
    String? note,
    DateTime? date,
    String? createdBy,
    TransferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transfer(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceWalletId: sourceWalletId ?? this.sourceWalletId,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destWalletId: destWalletId ?? this.destWalletId,
      destAccountId: destAccountId ?? this.destAccountId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transfer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transfer(id: $id, type: $type, amount: $amount, status: $status)';
  }
}

/// Transfer shortcut for quick actions
class TransferShortcut {
  final String id;
  final String name;
  final String sourceWalletId;
  final String destWalletId;
  final TransferType type;
  final int? defaultAmount;
  final DateTime createdAt;

  const TransferShortcut({
    required this.id,
    required this.name,
    required this.sourceWalletId,
    required this.destWalletId,
    required this.type,
    this.defaultAmount,
    required this.createdAt,
  });

  factory TransferShortcut.fromMap(String id, Map<String, dynamic> data) {
    return TransferShortcut(
      id: id,
      name: data['name'] ?? '',
      sourceWalletId: data['source_wallet_id'] ?? '',
      destWalletId: data['dest_wallet_id'] ?? '',
      type: TransferType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransferType.internal,
      ),
      defaultAmount: data['default_amount'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source_wallet_id': sourceWalletId,
      'dest_wallet_id': destWalletId,
      'type': type.name,
      if (defaultAmount != null) 'default_amount': defaultAmount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
