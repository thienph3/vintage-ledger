import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/repositories/wallet_repository.dart';
import 'package:vintage_ledger/features/transaction/repositories/transaction_repository.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class WalletService {
  final WalletRepository _repo = WalletRepository();
  final TransactionRepository _txnRepo = TransactionRepository();

  String get _accountId => sl.appState.currentAccountId;

  Future<int> createWallet(String name, int balance) async {
    if (name.trim().isEmpty) throw Exception("Wallet name cannot be empty");
    return await _repo.create(Wallet(
      name: name,
      balance: balance,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      accountId: _accountId,
    ));
  }

  Future<List<Wallet>> getWallets() async {
    return await _repo.getAll(accountId: _accountId);
  }

  Future<Wallet?> getWallet(int id) async {
    return await _repo.getById(id);
  }

  Future<int> updateWallet(int id, String name, int balance) async {
    final wallet = await _repo.getById(id);
    if (wallet == null) throw Exception("Wallet not found");

    final updated = Wallet(
      id: id,
      name: name,
      balance: balance,
      createdAt: wallet.createdAt,
    );

    return await _repo.update(updated, updatedAt: DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> deleteWallet(int id) async {
    await _txnRepo.deleteAllByWallet(id);
    return await _repo.delete(id);
  }
}
