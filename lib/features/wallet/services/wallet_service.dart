import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/repositories/wallet_repository.dart';

class WalletService {
  final WalletRepository _repo = WalletRepository();

  Stream<List<Wallet>> watchWallets() => _repo.watchWallets();

  Future<List<Wallet>> getWallets() => _repo.getAll();

  Future<Wallet?> getWallet(String id) => _repo.getById(id);

  Future<String> createWallet(String name, int balance) async {
    if (name.trim().isEmpty) throw Exception("Wallet name cannot be empty");
    return await _repo.add(Wallet(name: name, balance: balance));
  }

  Future<void> updateWallet(String id, String name, int balance) async {
    await _repo.update(id, {'name': name, 'balance': balance});
  }

  Future<void> deleteWallet(String id) async {
    await _repo.delete(id);
  }

  Future<void> updateBalance(String walletId, int delta) async {
    final wallet = await _repo.getById(walletId);
    if (wallet == null) throw Exception("Wallet not found");
    await _repo.update(walletId, {'balance': wallet.balance + delta});
  }
}
