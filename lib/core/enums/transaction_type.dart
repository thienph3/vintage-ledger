enum TransactionType {
  income,
  expense,
  transferOut,
  transferIn;

  String get value {
    switch (this) {
      case TransactionType.transferOut: return 'transfer_out';
      case TransactionType.transferIn: return 'transfer_in';
      default: return name;
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'transfer_out': return TransactionType.transferOut;
      case 'transfer_in': return TransactionType.transferIn;
      default:
        return TransactionType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => TransactionType.expense,
        );
    }
  }

  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
  bool get isTransfer => this == transferOut || this == transferIn;
  bool get isTransferOut => this == transferOut;
  bool get isTransferIn => this == transferIn;
}
