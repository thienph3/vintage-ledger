import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/sync/repositories/sync_repository.dart';
import 'package:vintage_ledger/features/settings/repositories/setting_repository.dart';

class SyncService {
  final SyncRepository _syncRepo = SyncRepository();
  final SettingRepository _settingRepo = SettingRepository();

  Future<bool> get _hasNetwork async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Sync tất cả accounts của user hiện tại
  Future<void> syncAll() async {
    if (!await _hasNetwork) throw Exception('No internet connection');

    final userId = sl.appState.currentUserId;
    if (userId == null) return;

    final accounts = await sl.accountService.getAccountsForUser(userId);
    for (final account in accounts) {
      await syncAccount(account.id);
    }
  }

  /// Sync 1 account: push dirty → pull new
  Future<void> syncAccount(String accountId) async {
    if (!await _hasNetwork) throw Exception('No internet connection');

    await _pushAccount(accountId);
    await _pullAccount(accountId);
  }

  // ── Push ──

  Future<void> _pushAccount(String accountId) async {
    await _pushCollection(accountId, 'wallets', await _syncRepo.getDirtyWallets(accountId));
    await _pushCollection(accountId, 'transactions', await _syncRepo.getDirtyTransactions(accountId));
    await _pushCollection(accountId, 'categories', await _syncRepo.getDirtyCategories(accountId));
    await _pushDeletes(accountId);

    await _settingRepo.set('sync_push_$accountId',
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<void> _pushCollection(
      String accountId, String collection, List<Map<String, dynamic>> dirtyRecords) async {
    if (dirtyRecords.isEmpty) return;

    final records = dirtyRecords.map((r) {
      final data = Map<String, dynamic>.from(r);
      final localId = data.remove('id') as int;
      final remoteId = data.remove('remote_id') as String?;
      data.remove('is_synced');
      data.remove('account_id');
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      return {'local_id': localId, 'remote_id': remoteId, 'data': data};
    }).toList();

    await _syncRepo.pushRecords(
      accountId: accountId,
      collection: collection,
      records: records,
    );

    final ids = records.map((r) => r['local_id'] as int).toList();
    await _syncRepo.markSynced(collection, ids);
  }

  // ── Pull ──

  Future<void> _pullAccount(String accountId) async {
    final lastPullStr = await _settingRepo.get('sync_pull_$accountId');
    final lastPullAt = lastPullStr != null ? int.parse(lastPullStr) : 0;

    await _pullCollection(accountId, 'wallets', lastPullAt);
    await _pullCollection(accountId, 'transactions', lastPullAt);
    await _pullCollection(accountId, 'categories', lastPullAt);

    await _settingRepo.set('sync_pull_$accountId',
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  Future<void> _pullCollection(
      String accountId, String collection, int lastPullAt) async {
    final docs = await _syncRepo.pullRecords(
      accountId: accountId,
      collection: collection,
      lastPullAt: lastPullAt,
    );

    // TODO Phase 4C: UPSERT vào SQLite by remote_id
    // Placeholder — sẽ implement chi tiết trong Phase 4C
    for (final doc in docs) {
      // doc.id = remote_id, doc.data() = fields
      _ = doc;
    }
  }

  Future<void> _pushDeletes(String accountId) async {
    final deletes = await _syncRepo.getPendingDeletes(accountId);
    if (deletes.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final accountDoc = firestore.collection('accounts').doc(accountId);

    for (final d in deletes) {
      final table = d['table_name'] as String;
      final remoteId = d['remote_id'] as String;
      batch.delete(accountDoc.collection(table).doc(remoteId));
    }
    await batch.commit();

    final ids = deletes.map((d) => d['id'] as int).toList();
    await _syncRepo.clearPendingDeletes(ids);
  }

  /// Đếm records chưa sync
  Future<int> getDirtyCount(String accountId) async {
    return await _syncRepo.getDirtyCount(accountId);
  }
}
