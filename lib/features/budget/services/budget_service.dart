import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/budget/models/budget.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/repositories/budget_repository.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';

class BudgetService {
  final BudgetRepository _repo = BudgetRepository();
  final TransactionRepository _txnRepo = TransactionRepository();

  Stream<List<Budget>> watchBudgets() => _repo.watchBudgets();

  Future<List<Budget>> getBudgets() async {
    return await _repo.getAll();
  }

  Future<String> createBudget(String categoryId, int amountLimit, {BudgetPeriod period = BudgetPeriod.monthly}) async {
    if (amountLimit <= 0) throw Exception("Budget limit must be > 0");
    final existing = await _repo.getByCategoryId(categoryId);
    if (existing != null) {
      await _repo.update(existing.id!, {'amount_limit': amountLimit, 'period': period.name});
      return existing.id!;
    }
    return await _repo.add(Budget(categoryId: categoryId, amountLimit: amountLimit, period: period));
  }

  Future<void> updateBudget(String id, int amountLimit, {BudgetPeriod? period}) async {
    final updates = <String, dynamic>{'amount_limit': amountLimit};
    if (period != null) updates['period'] = period.name;
    await _repo.update(id, updates);
  }

  Future<void> deleteBudget(String id) async {
    await _repo.delete(id);
  }

  /// Get budget statuses for a specific period anchor date
  Future<List<BudgetStatus>> getBudgetStatuses({DateTime? anchor}) async {
    final budgets = await _repo.getAll();
    if (budgets.isEmpty) return [];

    final now = anchor ?? DateTime.now();
    final categories = await sl.categoryService.getCategories();
    final catMap = {for (var c in categories) if (c.id != null) c.id!: c};

    // Determine the widest date range needed (all budgets share same anchor)
    // Use monthly range as the widest, weekly fits within it
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Single query: all expenses in the widest range
    final allTxns = await _txnRepo.getAll(queryBuilder: (ref) => ref
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: monthStart.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: monthEnd.millisecondsSinceEpoch));

    return budgets.map((b) {
      final range = _periodRange(b.period, now);
      final startMs = range.$1.millisecondsSinceEpoch;
      final endMs = range.$2.millisecondsSinceEpoch;

      // Filter in-memory for this budget's category and period
      final spent = allTxns
          .where((t) => t.transaction.categoryId == b.categoryId
              && t.transaction.date >= startMs
              && t.transaction.date <= endMs)
          .fold<int>(0, (s, t) => s + t.transaction.amount);

      final cat = catMap[b.categoryId];
      return BudgetStatus(
        budget: b,
        categoryName: cat?.name ?? '?',
        categoryIcon: cat?.icon,
        spent: spent,
        periodStart: range.$1,
        periodEnd: range.$2,
      );
    }).toList();
  }

  /// Check a single budget for current period
  Future<BudgetStatus?> checkBudget(String categoryId) async {
    final budget = await _repo.getByCategoryId(categoryId);
    if (budget == null) return null;

    final range = _periodRange(budget.period, DateTime.now());
    final spent = await _getSpentForCategory(categoryId, range.$1, range.$2);
    final cat = await sl.categoryService.getCategory(categoryId);

    return BudgetStatus(
      budget: budget,
      categoryName: cat?.name ?? '?',
      categoryIcon: cat?.icon,
      spent: spent,
      periodStart: range.$1,
      periodEnd: range.$2,
    );
  }

  /// Get transactions for a budget in a specific period (for detail screen)
  Future<List<({String note, int amount, int date})>> getBudgetTransactions(
    String categoryId, DateTime periodStart, DateTime periodEnd,
  ) async {
    final txns = await _txnRepo.getAll(queryBuilder: (ref) => ref
        .where('category_id', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: periodStart.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: periodEnd.millisecondsSinceEpoch));

    final results = txns.map((t) => (
      note: t.transaction.note ?? '',
      amount: t.transaction.amount,
      date: t.transaction.date,
    )).toList();
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  Future<int> _getSpentForCategory(String categoryId, DateTime start, DateTime end) async {
    final txns = await _txnRepo.getAll(queryBuilder: (ref) => ref
        .where('category_id', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: start.millisecondsSinceEpoch)
        .where('date', isLessThanOrEqualTo: end.millisecondsSinceEpoch));
    return txns.fold<int>(0, (s, t) => s + t.transaction.amount);
  }

  /// Calculate period range based on budget period type
  (DateTime, DateTime) _periodRange(BudgetPeriod period, DateTime anchor) {
    switch (period) {
      case BudgetPeriod.weekly:
        final weekday = anchor.weekday; // Monday = 1
        final start = DateTime(anchor.year, anchor.month, anchor.day - (weekday - 1));
        final end = DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
        return (start, end);
      case BudgetPeriod.monthly:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59);
        return (start, end);
    }
  }

  /// Navigate to previous/next period
  DateTime previousPeriod(BudgetPeriod period, DateTime anchor) {
    switch (period) {
      case BudgetPeriod.weekly:
        return anchor.subtract(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(anchor.year, anchor.month - 1, anchor.day);
    }
  }

  DateTime nextPeriod(BudgetPeriod period, DateTime anchor) {
    switch (period) {
      case BudgetPeriod.weekly:
        return anchor.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return DateTime(anchor.year, anchor.month + 1, anchor.day);
    }
  }
}
