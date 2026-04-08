/// Enum cho các loại quick action hiển thị trong FAB.
enum QuickActionType {
  funding,
  transfer,
  goalContribution,
  debtPayment,
}

/// Đầu vào cho visibility logic.
class QuickActionsInput {
  final bool isFamily;
  final int walletCount;
  final bool hasActiveGoals;
  final bool hasActiveDebts;

  const QuickActionsInput({
    required this.isFamily,
    required this.walletCount,
    required this.hasActiveGoals,
    required this.hasActiveDebts,
  });
}

/// Pure function xác định danh sách quick actions hiển thị.
class QuickActionsVisibility {
  /// Trả về danh sách [QuickActionType] theo thứ tự cố định
  /// dựa trên visibility rules từ [input].
  static List<QuickActionType> resolve(QuickActionsInput input) {
    return [
      if (input.isFamily) QuickActionType.funding,
      if (input.walletCount >= 2) QuickActionType.transfer,
      if (input.hasActiveGoals) QuickActionType.goalContribution,
      if (input.hasActiveDebts) QuickActionType.debtPayment,
    ];
  }
}
