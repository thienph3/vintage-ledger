import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
export 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
export 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';

class TransactionService {
  final TransactionRepository _repo = TransactionRepository();

  // ── Streams ──

  Stream<List<TransactionWithItems>> watchRecent(int limit, {String? walletId}) =>
      _repo.watchRecent(limit, walletId: walletId);

  Stream<List<TransactionWithItems>> watchByDateRange(int startDate, int endDate, {String? walletId}) =>
      _repo.watchByDateRange(startDate, endDate, walletId: walletId);

  // ── One-shot reads ──

  Future<DashboardData> getDashboard({String? walletId}) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final recent = await _repo.getRecent(5, walletId: walletId);
    final monthly = await _repo.getByDateRange(
      monthStart.millisecondsSinceEpoch,
      monthEnd.millisecondsSinceEpoch,
      walletId: walletId,
    );
    final categories = await sl.categoryService.getCategories();
    final categoryMap = {for (var c in categories) c.id!: c};

    int balance;
    if (walletId != null) {
      final wallet = await sl.walletService.getWallet(walletId);
      balance = wallet?.balance ?? 0;
    } else {
      final wallets = await sl.walletService.getWallets();
      balance = wallets.fold<int>(0, (sum, w) => sum + w.balance);
    }

    return DashboardData(
      recent: recent,
      monthly: monthly,
      categoryMap: categoryMap,
      balance: balance,
    );
  }

  // ── Create ──

  Future<String> createTransaction({
    required String walletId,
    required String categoryId,
    required TransactionType type,
    required int amount,
    String? note,
    required int date,
    List<TransactionItemModel> items = const [],
  }) async {
    if (amount <= 0) throw Exception("Amount must be greater than 0");

    final txn = TransactionWithItems(
      transaction: TransactionModel(
        walletId: walletId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        note: note,
        date: date,
        createdBy: sl.appState.currentUserId,
      ),
      items: items,
    );

    final id = await _repo.addTransaction(txn);

    // Update wallet balance
    final delta = type.isIncome ? amount : -amount;
    await sl.walletService.updateBalance(walletId, delta);

    return id;
  }

  // ── Update ──

  Future<void> updateTransaction(TransactionWithItems updated) async {
    final id = updated.transaction.id;
    if (id == null) throw Exception("Transaction ID required");

    // Get old transaction to revert balance
    final old = await _repo.getById(id);
    if (old != null) {
      final oldDelta = old.transaction.type.isIncome ? -old.transaction.amount : old.transaction.amount;
      await sl.walletService.updateBalance(old.transaction.walletId, oldDelta);
    }

    await _repo.updateTransaction(id, updated);

    // Apply new balance
    final newDelta = updated.transaction.type.isIncome ? updated.transaction.amount : -updated.transaction.amount;
    await sl.walletService.updateBalance(updated.transaction.walletId, newDelta);
  }

  // ── Delete ──

  Future<void> deleteTransaction(String id) async {
    final txn = await _repo.getById(id);
    if (txn == null) return;

    await _repo.delete(id);

    // Revert balance
    final delta = txn.transaction.type.isIncome ? -txn.transaction.amount : txn.transaction.amount;
    await sl.walletService.updateBalance(txn.transaction.walletId, delta);
  }

  // ── Items (embedded, no separate CRUD needed) ──

  Future<TransactionWithItems?> getTransactionWithItems(String id) => _repo.getById(id);
}
