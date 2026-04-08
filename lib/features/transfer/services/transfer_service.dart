import 'package:vintage_ledger/features/transfer/models/transfer.dart';
import 'package:vintage_ledger/features/transfer/repositories/transfer_repository.dart';

class TransferService {
  final _repo = TransferRepository();

  // ── Quick Actions ──

  Future<List<TransferShortcut>> getQuickTransferOptions() async {
    return await _repo.getShortcuts();
  }

  Stream<List<TransferShortcut>> watchShortcuts() {
    return _repo.watchShortcuts();
  }

  Future<void> saveTransferShortcut({
    required String name,
    required String fromWallet,
    required String toWallet,
    required TransferType type,
    int? defaultAmount,
  }) async {
    final shortcut = TransferShortcut(
      id: '',
      name: name,
      sourceWalletId: fromWallet,
      destWalletId: toWallet,
      type: type,
      defaultAmount: defaultAmount,
      createdAt: DateTime.now(),
    );
    await _repo.addShortcut(shortcut);
  }

  Future<void> deleteShortcut(String id) async {
    await _repo.deleteShortcut(id);
  }
}
