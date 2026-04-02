import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/features/insights/models/insight.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class InsightService {
  static List<Insight> generate(
    DashboardData dashboard,
    List<TransactionWithItems> lastWeekTxns,
    String locale,
  ) {
    final insights = <Insight>[];

    _addTopCategory(insights, dashboard, locale);
    _addWeeklyComparison(insights, dashboard, lastWeekTxns);
    _addSavings(insights, dashboard, locale);

    return insights;
  }

  static void _addTopCategory(List<Insight> list, DashboardData d, String locale) {
    if (d.expenseByCategory.isEmpty) return;
    final sorted = d.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final amount = AmountFormatter.formatCompactCurrency(top.value, locale);

    list.add(Insight(
      type: InsightType.topCategory,
      message: 'topSpendingInsight|${top.key}|$amount',
      icon: Icons.category,
      color: AppColors.expense,
    ));
  }

  static void _addWeeklyComparison(
    List<Insight> list,
    DashboardData d,
    List<TransactionWithItems> lastWeekTxns,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final thisWeekExpense = d.monthly
        .where((t) =>
            t.transaction.type == TransactionType.expense &&
            DateTime.fromMillisecondsSinceEpoch(t.transaction.date).isAfter(thisWeekStart))
        .fold<int>(0, (s, t) => s + t.transaction.amount);

    final lastWeekExpense = lastWeekTxns
        .where((t) => t.transaction.type == TransactionType.expense)
        .fold<int>(0, (s, t) => s + t.transaction.amount);

    if (lastWeekExpense == 0 || thisWeekExpense == 0) return;

    final pct = (((thisWeekExpense - lastWeekExpense) / lastWeekExpense) * 100).round().abs();
    if (pct < 5) return;

    final more = thisWeekExpense > lastWeekExpense;
    list.add(Insight(
      type: InsightType.weeklyChange,
      message: '${more ? 'weeklyMore' : 'weeklyLess'}|$pct',
      icon: more ? Icons.trending_up : Icons.trending_down,
      color: more ? AppColors.expense : AppColors.income,
    ));
  }

  static void _addSavings(List<Insight> list, DashboardData d, String locale) {
    final net = d.monthIncome - d.monthExpense;
    if (net <= 0) return;
    final amount = AmountFormatter.formatCompactCurrency(net, locale);

    list.add(Insight(
      type: InsightType.savings,
      message: 'savingsInsight|$amount',
      icon: Icons.savings,
      color: AppColors.income,
    ));
  }
}
