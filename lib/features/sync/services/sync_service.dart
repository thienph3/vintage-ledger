import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/database.dart';
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
    await _pushTransactions(accountId);
    await _pushCollection(accountId, 'categories', await _syncRepo.getDirtyCategories(accountId));
    await _pushDeletes(accountId);

    await _settingRepo.set('sync_push_$accountId',
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// Push transactions with embedded items
  Future<void> _pushTransactions(String accountId) async {
    final dirtyRecords = await _syncRepo.getDirtyTransactions(accountId);
    if (dirtyRecords.isEmpty) return;

    final db = await AppDatabase.instance.database;
    final records = <Map<String, dynamic>>[];

    for (final r in dirtyRecords) {
      final data = Map<String, dynamic>.from(r);
      final localId = data.remove('id') as int;
      final remoteId = data.remove('remote_id') as String?;
      data.remove('is_synced');
      data.remove('account_id');
      data['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      // Embed transaction_items
      final items = await db.query('transaction_items',
          where: 'transaction_id = ?', whereArgs: [localId]);
      data['items'] = items.map((i) => {
        'amount': i['amount'],
        'note': i['note'],
        'category_id': i['category_id'],
      }).toList();

      records.add({'local_id': localId, 'remote_id': remoteId, 'data': data});
    }

    final newMappings = await _syncRepo.pushRecords(
      accountId: accountId,
      collection: 'transactions',
      records: records,
    );

    for (final mapping in newMappings) {
      await _syncRepo.setRemoteId(
        'transactions',
        mapping['local_id'] as int,
        mapping['remote_id'] as String,
      );
    }

    final existingIds = records
        .where((r) => r['remote_id'] != null && (r['remote_id'] as String).isNotEmpty)
        .map((r) => r['local_id'] as int)
        .toList();
    await _syncRepo.markSynced('transactions', existingIds);
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

    // Push to Firestore, get remote_id mappings for new records
    final newMappings = await _syncRepo.pushRecords(
      accountId: accountId,
      collection: collection,
      records: records,
    );

    // Save remote_id for newly created records
    for (final mapping in newMappings) {
      await _syncRepo.setRemoteId(
        collection,
        mapping['local_id'] as int,
        mapping['remote_id'] as String,
      );
    }

    // Mark existing (already had remote_id) as synced
    final existingIds = records
        .where((r) => r['remote_id'] != null && (r['remote_id'] as String).isNotEmpty)
        .map((r) => r['local_id'] as int)
        .toList();
    await _syncRepo.markSynced(collection, existingIds);
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
