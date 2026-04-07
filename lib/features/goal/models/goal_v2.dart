enum GoalCategory { 
  vacation,
  emergency,
  purchase,
  education,
  wedding,
  home,
  car,
  investment,
  other;
  
  String get displayName {
    switch (this) {
      case GoalCategory.vacation:
        return 'Du lịch';
      case GoalCategory.emergency:
        return 'Khẩn cấp';
      case GoalCategory.purchase:
        return 'Mua sắm';
      case GoalCategory.education:
        return 'Giáo dục';
      case GoalCategory.wedding:
        return 'Đám cưới';
      case GoalCategory.home:
        return 'Nhà cửa';
      case GoalCategory.car:
        return 'Xe cộ';
      case GoalCategory.investment:
        return 'Đầu tư';
      case GoalCategory.other:
        return 'Khác';
    }
  }
  
  String get emoji {
    switch (this) {
      case GoalCategory.vacation:
        return '✈️';
      case GoalCategory.emergency:
        return '🚨';
      case GoalCategory.purchase:
        return '🛍️';
      case GoalCategory.education:
        return '📚';
      case GoalCategory.wedding:
        return '💒';
      case GoalCategory.home:
        return '🏠';
      case GoalCategory.car:
        return '🚗';
      case GoalCategory.investment:
        return '📈';
      case GoalCategory.other:
        return '🎯';
    }
  }
}

enum GoalStatus { 
  active, 
  paused, 
  completed, 
  cancelled;
  
  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return 'Đang hoạt động';
      case GoalStatus.paused:
        return 'Tạm dừng';
      case GoalStatus.completed:
        return 'Đã hoàn thành';
      case GoalStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

class GoalV2 {
  final String id;
  final String accountId;
  final String name;
  final GoalCategory category;
  final int targetAmount;
  final int currentAmount;
  final DateTime? targetDate;
  final String fundingWalletId;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalV2({
    required this.id,
    required this.accountId,
    required this.name,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.fundingWalletId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  int get remainingAmount => targetAmount - currentAmount;
  
  double get progressPercentage => targetAmount > 0 ? currentAmount / targetAmount : 0.0;
  
  bool get isCompleted => currentAmount >= targetAmount || status == GoalStatus.completed;
  
  bool get isActive => status == GoalStatus.active;
  
  bool get isPaused => status == GoalStatus.paused;
  
  bool get isOverdue {
    if (targetDate == null || isCompleted) return false;
    return DateTime.now().isAfter(targetDate!);
  }
  
  int get daysUntilTarget {
    if (targetDate == null) return 0;
    return targetDate!.difference(DateTime.now()).inDays;
  }
  
  String get displayTitle => '${category.emoji} $name';
  
  String get progressText => '${(progressPercentage * 100).toInt()}%';

  // Factory constructors
  factory GoalV2.fromMap(String id, Map<String, dynamic> data) {
    return GoalV2(
      id: id,
      accountId: data['account_id'] ?? '',
      name: data['name'] ?? '',
      category: GoalCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => GoalCategory.other,
      ),
      targetAmount: data['target_amount'] ?? 0,
      currentAmount: data['current_amount'] ?? 0,
      targetDate: data['target_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['target_date'])
          : null,
      fundingWalletId: data['funding_wallet_id'] ?? '',
      status: GoalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id': accountId,
      'name': name,
      'category': category.name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (targetDate != null) 'target_date': targetDate!.millisecondsSinceEpoch,
      'funding_wallet_id': fundingWalletId,
      'status': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  GoalV2 copyWith({
    String? id,
    String? accountId,
    String? name,
    GoalCategory? category,
    int? targetAmount,
    int? currentAmount,
    DateTime? targetDate,
    String? fundingWalletId,
    GoalStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalV2(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      fundingWalletId: fundingWalletId ?? this.fundingWalletId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalV2 && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GoalV2(id: $id, name: $name, category: $category, progress: ${progressPercentage.toStringAsFixed(2)})';
  }
}