import 'package:cloud_firestore/cloud_firestore.dart';
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
      recent: recent, monthly: monthly, categoryMap: categoryMap, balance: balance,
    );
  }

  // ── Atomic Create (#1) ──

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

    final firestore = _repo.firestore;
    final walletRef = sl.walletService.repo.collection.doc(walletId);
    final txnData = _repo.toFirestore(TransactionWithItems(
      transaction: TransactionModel(
        walletId: walletId, categoryId: categoryId, type: type,
        amount: amount, note: note, date: date,
        createdBy: sl.appState.currentUserId,
      ),
      items: items,
    ));
    txnData['created_at'] = FieldValue.serverTimestamp();
    txnData['updated_at'] = FieldValue.serverTimestamp();

    final delta = type.isIncome ? amount : -amount;

    final newDocRef = _repo.collection.doc();

    await firestore.runTransaction((txn) async {
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception("Wallet not found");
      final currentBalance = walletSnap.data()?['balance'] as int? ?? 0;

      txn.set(newDocRef, txnData);
      txn.update(walletRef, {'balance': currentBalance + delta});
    });

    _logActivity(type.value, amount, note);
    return newDocRef.id;
  }

  // ── Atomic Update (#2) ──

  Future<void> updateTransaction(TransactionWithItems updated) async {
    final id = updated.transaction.id;
    if (id == null) throw Exception("Transaction ID required");

    final firestore = _repo.firestore;
    final txnRef = _repo.collection.doc(id);

    final newData = _repo.toFirestore(updated);
    newData['updated_at'] = FieldValue.serverTimestamp();

    await firestore.runTransaction((txn) async {
      final oldSnap = await txn.get(txnRef);
      if (!oldSnap.exists) throw Exception("Transaction not found");
      final oldData = oldSnap.data()!;
      final oldType = TransactionType.fromString(oldData['type'] ?? 'expense');
      final oldAmount = oldData['amount'] as int? ?? 0;
      final oldWalletId = oldData['wallet_id'] as String? ?? '';
      final newWalletId = updated.transaction.walletId;
      final sameWallet = oldWalletId == newWalletId;

      if (sameWallet) {
        final walletRef = sl.walletService.repo.collection.doc(newWalletId);
        final walletSnap = await txn.get(walletRef);
        if (!walletSnap.exists) throw Exception("Wallet not found");
        var balance = walletSnap.data()?['balance'] as int? ?? 0;
        balance += oldType.isIncome ? -oldAmount : oldAmount;
        balance += updated.transaction.type.isIncome ? updated.transaction.amount : -updated.transaction.amount;
        txn.update(walletRef, {'balance': balance});
      } else {
        // Revert old wallet
        final oldWalletRef = sl.walletService.repo.collection.doc(oldWalletId);
        final oldWalletSnap = await txn.get(oldWalletRef);
        if (oldWalletSnap.exists) {
          final oldBalance = oldWalletSnap.data()?['balance'] as int? ?? 0;
          final revert = oldType.isIncome ? -oldAmount : oldAmount;
          txn.update(oldWalletRef, {'balance': oldBalance + revert});
        }
        // Apply to new wallet
        final newWalletRef = sl.walletService.repo.collection.doc(newWalletId);
        final newWalletSnap = await txn.get(newWalletRef);
        if (!newWalletSnap.exists) throw Exception("Wallet not found");
        final newBalance = newWalletSnap.data()?['balance'] as int? ?? 0;
        final apply = updated.transaction.type.isIncome ? updated.transaction.amount : -updated.transaction.amount;
        txn.update(newWalletRef, {'balance': newBalance + apply});
      }

      txn.update(txnRef, newData);
    });
  }

  // ── Atomic Delete (#3) ──

  Future<void> deleteTransaction(String id) async {
    final firestore = _repo.firestore;
    final txnRef = _repo.collection.doc(id);

    await firestore.runTransaction((txn) async {
      final txnSnap = await txn.get(txnRef);
      if (!txnSnap.exists) return;
      final data = txnSnap.data()!;
      final type = TransactionType.fromString(data['type'] ?? 'expense');
      final amount = data['amount'] as int? ?? 0;
      final walletId = data['wallet_id'] as String? ?? '';

      if (walletId.isNotEmpty) {
        final walletRef = sl.walletService.repo.collection.doc(walletId);
        final walletSnap = await txn.get(walletRef);
        if (walletSnap.exists) {
          final balance = walletSnap.data()?['balance'] as int? ?? 0;
          final delta = type.isIncome ? -amount : amount;
          txn.update(walletRef, {'balance': balance + delta});
        }
      }

      txn.delete(txnRef);
    });
  }

  // ── Items (embedded) ──

  Future<TransactionWithItems?> getTransactionWithItems(String id) => _repo.getById(id);

  /// Direct date range query (for TransactionListScreen lazy loading)
  Future<List<TransactionWithItems>> getByDateRange(int startDate, int endDate, {String? walletId}) =>
      _repo.getByDateRange(startDate, endDate, walletId: walletId);

  void _logActivity(String action, int amount, String? note) {
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId;
    if (accountId.isEmpty || userId == null) return;

    final desc = note != null && note.isNotEmpty ? '$amount - $note' : '$amount';
    sl.accountService.logActivity(
      accountId: accountId, userId: userId, action: action, description: desc,
    );
  }
}
