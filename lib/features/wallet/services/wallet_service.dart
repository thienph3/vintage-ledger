import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/repositories/wallet_repository.dart';

class WalletService {
  final WalletRepository _repo = WalletRepository();

  /// Exposed for atomic Firestore transactions
  WalletRepository get repo => _repo;

  Stream<List<Wallet>> watchWallets() => _repo.watchWallets();

  Future<List<Wallet>> getWallets() => _repo.getAll();

  Future<Wallet?> getWallet(String id) => _repo.getById(id);

  Future<String> createWallet(String name, int balance, {String currency = 'VND'}) async {
    if (name.trim().isEmpty) throw Exception("Wallet name cannot be empty");
    return await _repo.add(Wallet(name: name, balance: balance, currency: currency));
  }

  Future<void> updateWallet(String id, String name, int balance, {String? currency}) async {
    final data = <String, dynamic>{'name': name, 'balance': balance};
    if (currency != null) data['currency'] = currency;
    await _repo.update(id, data);
  }

  Future<void> deleteWallet(String id) async {
    await _repo.delete(id);
  }

  /// Recalculate balance from all transactions (fix tool for inconsistent data)
  Future<void> recalculateBalance(String walletId) async {
    final txns = await sl.transactionService.getDashboard(walletId: walletId);
    // Use all-time transactions, not just monthly
    final allTxns = await FirebaseFirestore.instance
        .collection('accounts').doc(sl.appState.currentAccountId)
        .collection('transactions')
        .where('wallet_id', isEqualTo: walletId)
        .get();

    int balance = 0;
    for (final doc in allTxns.docs) {
      final data = doc.data();
      final type = TransactionType.fromString(data['type'] ?? 'expense');
      final amount = data['amount'] as int? ?? 0;
      balance += type.isIncome ? amount : -amount;
    }

    await _repo.update(walletId, {'balance': balance});
  }
}
