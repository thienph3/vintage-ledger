import '../models/transaction.dart';
import '../models/transaction_item.dart';
import '../models/wallet.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/transaction_item_repository.dart';
import '../repositories/wallet_repository.dart';

/// Helper để kết hợp transaction + items
class TransactionWithItems {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;

  TransactionWithItems({
    required this.transaction,
    this.items = const [],
  });

  /// Phần dư chưa phân bổ
  int get remainingAmount {
    final totalItems = items.fold(0, (sum, item) => sum + item.amount);
    return transaction.amount - totalItems;
  }
}

class TransactionService {
  final TransactionRepository _repo = TransactionRepository();
  final TransactionItemRepository _itemRepo = TransactionItemRepository();
  final WalletRepository _walletRepo = WalletRepository();

  /// CREATE TRANSACTION
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

    final wallet = await _walletRepo.getById(walletId);
    if (wallet == null) {
      throw Exception("Wallet not found");
    }

    int newBalance = wallet.balance;
    if (type == "income") {
      newBalance += amount;
    } else {
      newBalance -= amount;
    }

    await _walletRepo.update(
      Wallet(
        id: wallet.id,
        name: wallet.name,
        balance: newBalance,
        createdAt: wallet.createdAt,
      ),
    );

    final transaction = TransactionModel(
      walletId: walletId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note,
      date: date,
    );

    return await _repo.create(transaction);
  }

  /// READ ALL TRANSACTIONS (load items)
  Future<List<TransactionWithItems>> getTransactionsWithItems() async {
    final transactions = await _repo.getAll();
    final result = <TransactionWithItems>[];

    for (var t in transactions) {
      final items = await _itemRepo.getByTransaction(t.id!);
      result.add(TransactionWithItems(transaction: t, items: items));
    }

    return result;
  }

  /// READ BY WALLET (load items)
  Future<List<TransactionWithItems>> getByWalletWithItems(int walletId) async {
    final transactions = await _repo.getByWallet(walletId);
    final result = <TransactionWithItems>[];

    for (var t in transactions) {
      final items = await _itemRepo.getByTransaction(t.id!);
      result.add(TransactionWithItems(transaction: t, items: items));
    }

    return result;
  }

  /// READ SINGLE TRANSACTION (with items)
  Future<TransactionWithItems?> getTransactionWithItems(int id) async {
    final transaction = await _repo.getById(id);
    if (transaction == null) return null;
    final items = await _itemRepo.getByTransaction(transaction.id!);
    return TransactionWithItems(transaction: transaction, items: items);
  }

  /// UPDATE TRANSACTION
  Future<int> updateTransaction(TransactionModel transaction) async {
    final existing = await _repo.getById(transaction.id!);
    if (existing == null) {
      throw Exception("Transaction not found");
    }

    final wallet = await _walletRepo.getById(existing.walletId);
    if (wallet == null) {
      throw Exception("Wallet not found");
    }

    int newBalance = wallet.balance;
    if (existing.type == "income") {
      newBalance -= existing.amount;
    } else {
      newBalance += existing.amount;
    }

    if (transaction.type == "income") {
      newBalance += transaction.amount;
    } else {
      newBalance -= transaction.amount;
    }

    await _walletRepo.update(
      Wallet(
        id: wallet.id,
        name: wallet.name,
        balance: newBalance,
        createdAt: wallet.createdAt,
      ),
    );

    return await _repo.update(transaction);
  }

  /// DELETE TRANSACTION (and its items)
  Future<int> deleteTransaction(int id) async {
    final transaction = await _repo.getById(id);
    if (transaction == null) throw Exception("Transaction not found");

    // Update wallet
    final wallet = await _walletRepo.getById(transaction.walletId);
    if (wallet != null) {
      int newBalance = wallet.balance;
      if (transaction.type == "income") {
        newBalance -= transaction.amount;
      } else {
        newBalance += transaction.amount;
      }
      await _walletRepo.update(
        Wallet(
          id: wallet.id,
          name: wallet.name,
          balance: newBalance,
          createdAt: wallet.createdAt,
        ),
      );
    }

    // Delete items first
    final items = await _itemRepo.getByTransaction(id);
    for (var item in items) {
      await _itemRepo.delete(item.id!);
    }

    return await _repo.delete(id);
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

  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    return await _itemRepo.getByTransaction(transactionId);
  }
}