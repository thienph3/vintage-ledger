import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
export 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_item_repository.dart';
import 'package:vintage_ledger/features/wallet/repositories/wallet_repository.dart';
import 'package:vintage_ledger/features/category/repositories/category_repository.dart';

class DashboardData {
  final List<TransactionWithItems> recent;
  final List<TransactionWithItems> monthly;
  final Map<int, Category> categoryMap;
  final int balance;

  const DashboardData({
    required this.recent,
    required this.monthly,
    required this.categoryMap,
    required this.balance,
  });
}

class TransactionService {
  final TransactionRepository _repo = TransactionRepository();
  final TransactionItemRepository _itemRepo = TransactionItemRepository();
  final WalletRepository _walletRepo = WalletRepository();
  final CategoryRepository _catRepo = CategoryRepository();

  /// Load dashboard data for Home or WalletDetail screen.
  Future<DashboardData> getDashboard({int? walletId}) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final recent = await getRecentWithItems(5, walletId: walletId);
    final monthly = await getByDateRangeWithItems(
      monthStart.millisecondsSinceEpoch,
      monthEnd.millisecondsSinceEpoch,
      walletId: walletId,
    );
    final categories = await _catRepo.getAll();
    final categoryMap = {for (var c in categories) c.id!: c};

    int balance;
    if (walletId != null) {
      final wallet = await _walletRepo.getById(walletId);
      balance = wallet?.balance ?? 0;
    } else {
      final wallets = await _walletRepo.getAll();
      balance = wallets.fold<int>(0, (sum, w) => sum + w.balance);
    }

    return DashboardData(
      recent: recent,
      monthly: monthly,
      categoryMap: categoryMap,
      balance: balance,
    );
  }

  /// CREATE TRANSACTION (atomic: update balance + insert in one DB transaction)
  Future<int> createTransaction({
    required int walletId,
    required int categoryId,
    required String type,
    required int amount,
    String? note,
    required int date,
  }) async {
    if (amount <= 0) {
      throw Exception("Amount must be greater than 0");
    }

    if (type != "income" && type != "expense") {
      throw Exception("Invalid transaction type");
    }

    final db = await AppDatabase.instance.database;

    return await db.transaction((txn) async {
      final walletResult = await txn.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [walletId],
        limit: 1,
      );
      if (walletResult.isEmpty) throw Exception("Wallet not found");

      final wallet = Wallet.fromMap(walletResult.first);
      final newBalance = type == "income"
          ? wallet.balance + amount
          : wallet.balance - amount;

      await txn.update(
        'wallets',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [walletId],
      );

      return await txn.insert('transactions', {
        'wallet_id': walletId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'note': note,
        'date': date,
      });
    });
  }

  /// READ RECENT (with optional wallet filter)
  Future<List<TransactionWithItems>> getRecentWithItems(
    int limit, {
    int? walletId,
  }) async {
    final transactions = await _repo.getRecent(limit, walletId: walletId);
    return _attachItems(transactions);
  }

  /// READ BY DATE RANGE (with optional wallet filter)
  Future<List<TransactionWithItems>> getByDateRangeWithItems(
    int startDate,
    int endDate, {
    int? walletId,
  }) async {
    final transactions = await _repo.getByDateRange(
      startDate,
      endDate,
      walletId: walletId,
    );
    return _attachItems(transactions);
  }

  /// READ SINGLE TRANSACTION (with items)
  Future<TransactionWithItems?> getTransactionWithItems(int id) async {
    final transaction = await _repo.getById(id);
    if (transaction == null) return null;
    final items = await _itemRepo.getByTransaction(transaction.id!);
    return TransactionWithItems(transaction: transaction, items: items);
  }

  /// UPDATE TRANSACTION (atomic: revert old balance + apply new balance + update row)
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await AppDatabase.instance.database;

    return await db.transaction((txn) async {
      final existingResult = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
        limit: 1,
      );
      if (existingResult.isEmpty) throw Exception("Transaction not found");

      final existing = TransactionModel.fromMap(existingResult.first);

      final walletResult = await txn.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [existing.walletId],
        limit: 1,
      );
      if (walletResult.isEmpty) throw Exception("Wallet not found");

      final wallet = Wallet.fromMap(walletResult.first);

      // Revert old transaction effect
      int newBalance = wallet.balance;
      newBalance += existing.type == "income" ? -existing.amount : existing.amount;

      // Apply new transaction effect
      newBalance += transaction.type == "income" ? transaction.amount : -transaction.amount;

      await txn.update(
        'wallets',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [wallet.id],
      );

      return await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  /// DELETE TRANSACTION (atomic: revert balance + batch delete items + delete row)
  Future<int> deleteTransaction(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.transaction((txn) async {
      final txnResult = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (txnResult.isEmpty) throw Exception("Transaction not found");

      final transaction = TransactionModel.fromMap(txnResult.first);

      final walletResult = await txn.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [transaction.walletId],
        limit: 1,
      );

      if (walletResult.isNotEmpty) {
        final wallet = Wallet.fromMap(walletResult.first);
        final newBalance = transaction.type == "income"
            ? wallet.balance - transaction.amount
            : wallet.balance + transaction.amount;

        await txn.update(
          'wallets',
          {'balance': newBalance},
          where: 'id = ?',
          whereArgs: [wallet.id],
        );
      }

      // Batch delete items instead of loop
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      return await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// DELETE ALL TRANSACTIONS FOR A WALLET
  Future<void> deleteAllByWallet(int walletId) async {
    await _repo.deleteAllByWallet(walletId);
  }

  // ========================
  // TRANSACTION ITEM CRUD
  // ========================

  Future<int> addTransactionItem(TransactionItemModel item) async {
    return await _itemRepo.create(item);
  }

  Future<int> updateTransactionItem(TransactionItemModel item) async {
    return await _itemRepo.update(item);
  }

  Future<int> deleteTransactionItem(int id) async {
    return await _itemRepo.delete(id);
  }

  Future<List<TransactionItemModel>> getTransactionItems(
    int transactionId,
  ) async {
    return await _itemRepo.getByTransaction(transactionId);
  }

  // ========================
  // PRIVATE HELPERS
  // ========================

  /// Batch load items for multiple transactions (fixes N+1 query)
  Future<List<TransactionWithItems>> _attachItems(
    List<TransactionModel> transactions,
  ) async {
    if (transactions.isEmpty) return [];

    final ids = transactions.map((t) => t.id!).toList();
    final itemsMap = await _itemRepo.getByTransactionIds(ids);

    return transactions.map((t) {
      return TransactionWithItems(
        transaction: t,
        items: itemsMap[t.id!] ?? [],
      );
    }).toList();
  }
}
