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
    final id = await _repo.add(Wallet(name: name, balance: balance, currency: currency));
    _log('wallet', 'đã tạo ví $name');
    return id;
  }

  Future<void> updateWallet(String id, String name, int balance, {String? currency}) async {
    final data = <String, dynamic>{'name': name, 'balance': balance};
    if (currency != null) data['currency'] = currency;
    await _repo.update(id, data);
  }

  Future<void> deleteWallet(String id) async {
    final wallet = await _repo.getById(id);
    await _repo.delete(id);
    if (wallet != null) _log('wallet', 'đã xóa ví ${wallet.name}');
  }

  /// Recalculate balance from all transactions (fix tool for inconsistent data)
  Future<void> recalculateBalance(String walletId) async {
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

  void _log(String action, String description) {
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId;
    if (accountId.isEmpty || userId == null) return;
    sl.accountService.logActivity(
      accountId: accountId, userId: userId, action: action, description: description,
    );
  }
}
