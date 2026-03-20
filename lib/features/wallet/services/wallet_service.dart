import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/repositories/wallet_repository.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';

class WalletService {
  final WalletRepository _repo = WalletRepository();
  final TransactionService _transactionService = TransactionService();

  /// CREATE WALLET
  Future<int> createWallet(String name, int balance) async {
    if (name.trim().isEmpty) {
      throw Exception("Wallet name cannot be empty");
    }

    final wallet = Wallet(
      name: name,
      balance: balance,
      createdAt: DateTime.now().toIso8601String(),
    );

    return await _repo.create(wallet);
  }

  /// GET ALL WALLETS
  Future<List<Wallet>> getWallets() async {
    return await _repo.getAll();
  }

  /// GET WALLET BY ID
  Future<Wallet?> getWallet(int id) async {
    return await _repo.getById(id);
  }

  /// UPDATE WALLET
  Future<int> updateWallet(int id, String name, int balance) async {
    final wallet = await _repo.getById(id);
    if (wallet == null) {
      throw Exception("Wallet not found");
    }

    final updated = Wallet(
      id: id,
      name: name,
      balance: balance,
      createdAt: wallet.createdAt,
    );

    return await _repo.update(updated);
  }

  /// DELETE WALLET
  /// Xóa hết transaction liên quan trước khi xóa wallet
  Future<int> deleteWallet(int id) async {
    // Xóa tất cả giao dịch liên quan
    final transactions = await _transactionService.getByWalletWithItems(id);
    for (var t in transactions) {
      await _transactionService.deleteTransaction(t.transaction.id!);
    }

    // Sau đó xóa ví
    return await _repo.delete(id);
  }
}