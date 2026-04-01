import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/budget/models/budget.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/repositories/budget_repository.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';

class BudgetService {
  final BudgetRepository _repo = BudgetRepository();
  final TransactionRepository _txnRepo = TransactionRepository();

  Stream<List<Budget>> watchBudgets() => _repo.watchBudgets();

  Future<List<Budget>> getBudgets() => _repo.getAll();

  Future<String> createBudget(String categoryId, int amountLimit) async {
    if (amountLimit <= 0) throw Exception("Budget limit must be > 0");
    final existing = await _repo.getByCategoryId(categoryId);
    if (existing != null) {
      await _repo.update(existing.id!, {'amount_limit': amountLimit});
      return existing.id!;
    }
    return await _repo.add(Budget(categoryId: categoryId, amountLimit: amountLimit));
  }

  Future<void> updateBudget(String id, int amountLimit) async {
    await _repo.update(id, {'amount_limit': amountLimit});
  }

  Future<void> deleteBudget(String id) async {
    await _repo.delete(id);
  }

  /// #1: Query expense transactions directly, not via getDashboard
  Future<List<BudgetStatus>> getBudgetStatuses() async {
    final budgets = await _repo.getAll();
    if (budgets.isEmpty) return [];

    final spentMap = await _getMonthlyExpenseByCategory();
    final categories = await sl.categoryService.getCategories();
    final catMap = {for (var c in categories) c.id!: c};

    return budgets.map((b) {
      final cat = catMap[b.categoryId];
      return BudgetStatus(
        budget: b,
        categoryName: cat?.name ?? '?',
        categoryIcon: cat?.icon,
        spent: spentMap[b.categoryId] ?? 0,
      );
    }).toList();
  }

  /// #2: Query only transactions for 1 category in current month
  Future<BudgetStatus?> checkBudget(String categoryId) async {
    final budget = await _repo.getByCategoryId(categoryId);
    if (budget == null) return null;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

    // Query only this category's expense transactions
    final txns = await _txnRepo.getAll(queryBuilder: (ref) => ref
        .where('category_id', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThanOrEqualTo: monthEnd));

    final spent = txns.fold<int>(0, (s, t) => s + t.transaction.amount);
    final cat = await sl.categoryService.getCategory(categoryId);

    return BudgetStatus(
      budget: budget,
      categoryName: cat?.name ?? '?',
      categoryIcon: cat?.icon,
      spent: spent,
    );
  }

  /// Query all expense transactions this month, group by categoryId
  Future<Map<String, int>> _getMonthlyExpenseByCategory() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

    final txns = await _txnRepo.getAll(queryBuilder: (ref) => ref
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: monthStart)
        .where('date', isLessThanOrEqualTo: monthEnd));

    final map = <String, int>{};
    for (final t in txns) {
      final catId = t.transaction.categoryId;
      map[catId] = (map[catId] ?? 0) + t.transaction.amount;
    }
    return map;
  }
}
