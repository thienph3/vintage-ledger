import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/budget/models/budget.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/repositories/budget_repository.dart';

class BudgetService {
  final BudgetRepository _repo = BudgetRepository();

  Stream<List<Budget>> watchBudgets() => _repo.watchBudgets();

  Future<List<Budget>> getBudgets() => _repo.getAll();

  Future<String> createBudget(String categoryId, int amountLimit) async {
    if (amountLimit <= 0) throw Exception("Budget limit must be > 0");
    // Upsert: nếu đã có budget cho category này thì update
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

  /// Tính budget status cho tháng hiện tại
  Future<List<BudgetStatus>> getBudgetStatuses() async {
    final budgets = await _repo.getAll();
    if (budgets.isEmpty) return [];

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

    // Lấy tất cả transactions tháng này
    final txnRepo = sl.transactionService;
    final dashboard = await txnRepo.getDashboard();
    final categories = dashboard.categoryMap;

    // Tính spent per category từ monthly transactions
    final spentMap = <String, int>{};
    for (final t in dashboard.monthly) {
      if (t.transaction.type != TransactionType.expense) continue;
      final catId = t.transaction.categoryId;
      spentMap[catId] = (spentMap[catId] ?? 0) + t.transaction.amount;
    }

    return budgets.map((b) {
      final cat = categories[b.categoryId];
      return BudgetStatus(
        budget: b,
        categoryName: cat?.name ?? '?',
        categoryIcon: cat?.icon,
        spent: spentMap[b.categoryId] ?? 0,
      );
    }).toList();
  }

  /// Check budget cho 1 category (dùng cho alert trong form)
  Future<BudgetStatus?> checkBudget(String categoryId) async {
    final budget = await _repo.getByCategoryId(categoryId);
    if (budget == null) return null;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

    final dashboard = await sl.transactionService.getDashboard();
    int spent = 0;
    for (final t in dashboard.monthly) {
      if (t.transaction.type == TransactionType.expense && t.transaction.categoryId == categoryId) {
        spent += t.transaction.amount;
      }
    }

    final cat = dashboard.categoryMap[categoryId];
    return BudgetStatus(
      budget: budget,
      categoryName: cat?.name ?? '?',
      categoryIcon: cat?.icon,
      spent: spent,
    );
  }
}
