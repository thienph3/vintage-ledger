import 'package:vintage_ledger/features/budget/models/budget.dart';

class BudgetStatus {
  final Budget budget;
  final String categoryName;
  final int? categoryIcon;
  final int spent;
  final DateTime periodStart;
  final DateTime periodEnd;

  BudgetStatus({
    required this.budget,
    required this.categoryName,
    this.categoryIcon,
    required this.spent,
    required this.periodStart,
    required this.periodEnd,
  });

  int get remaining => budget.amountLimit - spent;
  double get percentage => budget.amountLimit > 0 ? spent / budget.amountLimit : 0;
  bool get isExceeded => spent > budget.amountLimit;
  bool get isNearLimit => percentage >= 0.8 && !isExceeded;
}
