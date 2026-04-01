import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

class DashboardData {
  final List<TransactionWithItems> recent;
  final List<TransactionWithItems> monthly;
  final Map<String, Category> categoryMap;
  final int balance;

  late final Map<DateTime, Map<String, int>> dailyData;
  late final Map<String, int> expenseByCategory;
  late final int monthIncome;
  late final int monthExpense;

  DashboardData({
    required this.recent,
    required this.monthly,
    required this.categoryMap,
    required this.balance,
  }) {
    dailyData = _buildDailyData();
    expenseByCategory = _buildExpenseByCategory();
    monthIncome = _totalByType(TransactionType.income);
    monthExpense = _totalByType(TransactionType.expense);
  }

  Map<DateTime, Map<String, int>> _buildDailyData() {
    final map = <DateTime, Map<String, int>>{};
    for (var t in monthly) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      final day = DateTime(dt.year, dt.month, dt.day);
      map.putIfAbsent(day, () => {'income': 0, 'expense': 0});
      map[day]![t.transaction.type.value] =
          map[day]![t.transaction.type.value]! + t.transaction.amount;
    }
    return map;
  }

  Map<String, int> _buildExpenseByCategory() {
    final map = <String, int>{};
    for (var t in monthly) {
      if (t.transaction.type != TransactionType.expense) continue;
      final name = categoryMap[t.transaction.categoryId]?.name ?? '?';
      map[name] = (map[name] ?? 0) + t.transaction.amount;
    }
    return map;
  }

  int _totalByType(TransactionType type) => monthly
      .where((t) => t.transaction.type == type)
      .fold(0, (s, t) => s + t.transaction.amount);
}
