class PaymentResult {
  final String transactionId;
  final int previousNextRunAt;
  final String ruleId;
  final String? linkedDebtId;
  final String? linkedGoalId;
  final int amount;

  PaymentResult({
    required this.transactionId,
    required this.previousNextRunAt,
    required this.ruleId,
    this.linkedDebtId,
    this.linkedGoalId,
    required this.amount,
  });
}
