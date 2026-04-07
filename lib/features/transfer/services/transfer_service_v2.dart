import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/transfer/models/transfer_v2.dart';
import 'package:vintage_ledger/features/transfer/repositories/transfer_repository_v2.dart';

class TransferServiceV2 {
  final _repo = TransferRepositoryV2();

  // ── Internal Transfers ──

  Future<String> chuyenGiuaCacVi({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now();
    final transfer = TransferV2(
      id: '',
      type: TransferType.internal,
      sourceWalletId: fromWalletId,
      sourceAccountId: sl.appState.currentAccountId,
      destWalletId: toWalletId,
      destAccountId: sl.appState.currentAccountId,
      amount: amount,
      note: note,
      date: now,
      createdBy: sl.appState.currentUserId,
      status: TransferStatus.completed,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addTransfer(transfer);
  }

  // ── Family Funding ──

  Future<String> napVaoViGiaDinh({
    required String personalWalletId,
    required String familyWalletId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now();
    final transfer = TransferV2(
      id: '',
      type: TransferType.funding,
      sourceWalletId: personalWalletId,
      sourceAccountId: sl.appState.currentAccountId,
      destWalletId: familyWalletId,
      amount: amount,
      note: note ?? 'Nạp vào ví gia đình',
      date: now,
      createdBy: sl.appState.currentUserId,
      status: TransferStatus.completed,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addTransfer(transfer);
  }

  Future<String> napChoChiTieu({
    required String personalWalletId,
    required String familyWalletId,
    required int amount,
    required String categoryId,
    String? note,
  }) async {
    final now = DateTime.now();
    final transfer = TransferV2(
      id: '',
      type: TransferType.funding,
      sourceWalletId: personalWalletId,
      sourceAccountId: sl.appState.currentAccountId,
      destWalletId: familyWalletId,
      amount: amount,
      note: note ?? 'Nạp cho chi tiêu',
      date: now,
      createdBy: sl.appState.currentUserId,
      status: TransferStatus.completed,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addTransfer(transfer);
  }

  // ── Cross-Account Transfers ──

  Future<String> guiChoThanhVien({
    required String fromWalletId,
    required String toAccountId,
    required String toWalletId,
    required int amount,
    String? note,
  }) async {
    final now = DateTime.now();
    final transfer = TransferV2(
      id: '',
      type: TransferType.crossAccount,
      sourceWalletId: fromWalletId,
      sourceAccountId: sl.appState.currentAccountId,
      destWalletId: toWalletId,
      destAccountId: toAccountId,
      amount: amount,
      note: note,
      date: now,
      createdBy: sl.appState.currentUserId,
      status: TransferStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addTransfer(transfer);
  }

  // ── Queries ──

  Future<List<TransferV2>> getLichSuChuyenTien() async {
    return await _repo.getTransfers();
  }

  Future<List<TransferV2>> getTransfersByType(TransferType type) async {
    return await _repo.getTransfersByType(type);
  }

  Future<List<TransferV2>> getPendingTransfers() async {
    return await _repo.getPendingTransfers();
  }

  Stream<List<TransferV2>> watchRecentTransfers() {
    return _repo.watchRecentTransfers();
  }

  Future<TransferV2?> getTransfer(String id) async {
    return await _repo.getTransfer(id);
  }

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

  // ── Management ──

  Future<void> updateTransferStatus(String id, TransferStatus status) async {
    await _repo.updateTransfer(id, {'status': status.name});
  }

  Future<void> deleteTransfer(String id) async {
    await _repo.deleteTransfer(id);
  }
}
