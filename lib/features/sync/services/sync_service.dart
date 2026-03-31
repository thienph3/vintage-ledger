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

  /// Sync tất cả accounts của user hiện tại. Returns list of errors (empty = success).
  Future<List<String>> syncAll() async {
    if (!await _hasNetwork) throw Exception('No internet connection');

    final userId = sl.appState.currentUserId;
    if (userId == null) return [];

    final accounts = await sl.accountService.getAccountsForUser(userId);
    final errors = <String>[];
    for (final account in accounts) {
      try {
        await syncAccount(account.id);
      } catch (e) {
        errors.add('${account.name}: $e');
      }
    }
    return errors;
  }

  /// Sync 1 account: push dirty → pull new → cleanup tombstones (1 lần/ngày)
  Future<void> syncAccount(String accountId) async {
    if (!await _hasNetwork) throw Exception('No internet connection');

    try {
      await _pushAccount(accountId);
    } catch (e) {
      rethrow;
    }

    await _pullAccount(accountId);
    await _maybeCleanupTombstones(accountId);
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

    await _pullWallets(accountId, lastPullAt);
    await _pullTransactions(accountId, lastPullAt);
    await _pullCategories(accountId, lastPullAt);

    await _settingRepo.set('sync_pull_$accountId',
        DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// #12 — Pull wallets
  Future<void> _pullWallets(String accountId, int lastPullAt) async {
    final docs = await _syncRepo.pullRecords(
      accountId: accountId, collection: 'wallets', lastPullAt: lastPullAt,
    );

    final changedWalletIds = <int>[];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // #15 — Soft delete: Firestore doc đã bị xóa (ko có trong pull vì đã delete)
      // Nhưng nếu có field deleted_at → xóa local
      if (data['deleted_at'] != null) {
        final db = await AppDatabase.instance.database;
        await db.delete('wallets',
            where: 'remote_id = ? AND account_id = ?',
            whereArgs: [doc.id, accountId]);
        continue;
      }

      final localId = await _syncRepo.upsertByRemoteId(
        table: 'wallets',
        remoteId: doc.id,
        accountId: accountId,
        data: {
          'name': data['name'],
          'balance': data['balance'] ?? 0,
          'created_at': data['created_at'] ?? 0,
          'updated_at': data['updated_at'],
        },
      );
      if (localId >= 0) changedWalletIds.add(localId);
    }

    // #16 — Recalculate balances
    for (final id in changedWalletIds) {
      await AppDatabase.instance.recalculateBalance(id);
    }
  }

  /// #13 — Pull transactions (extract embedded items)
  Future<void> _pullTransactions(String accountId, int lastPullAt) async {
    final docs = await _syncRepo.pullRecords(
      accountId: accountId, collection: 'transactions', lastPullAt: lastPullAt,
    );

    final walletIdsToRecalc = <int>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['deleted_at'] != null) {
        final db = await AppDatabase.instance.database;
        // Lấy wallet_id trước khi xóa để recalc
        final existing = await db.query('transactions',
            columns: ['wallet_id'],
            where: 'remote_id = ? AND account_id = ?',
            whereArgs: [doc.id, accountId], limit: 1);
        if (existing.isNotEmpty) {
          walletIdsToRecalc.add(existing.first['wallet_id'] as int);
        }
        await db.delete('transactions',
            where: 'remote_id = ? AND account_id = ?',
            whereArgs: [doc.id, accountId]);
        continue;
      }

      final items = data.remove('items') as List<dynamic>? ?? [];

      final localId = await _syncRepo.upsertByRemoteId(
        table: 'transactions',
        remoteId: doc.id,
        accountId: accountId,
        data: {
          'wallet_id': data['wallet_id'],
          'category_id': data['category_id'],
          'type': data['type'],
          'amount': data['amount'],
          'note': data['note'],
          'date': data['date'],
          'created_by': data['created_by'],
          'updated_at': data['updated_at'],
        },
      );

      if (localId < 0) continue; // skipped — local is newer

      // Extract embedded items → transaction_items table
      await _syncRepo.upsertTransactionItems(localId, items);
      walletIdsToRecalc.add(data['wallet_id'] as int);
    }

    for (final id in walletIdsToRecalc) {
      await AppDatabase.instance.recalculateBalance(id);
    }
  }

  /// #14 — Pull categories
  Future<void> _pullCategories(String accountId, int lastPullAt) async {
    final docs = await _syncRepo.pullRecords(
      accountId: accountId, collection: 'categories', lastPullAt: lastPullAt,
    );

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['deleted_at'] != null) {
        final db = await AppDatabase.instance.database;
        await db.delete('categories',
            where: 'remote_id = ? AND account_id = ?',
            whereArgs: [doc.id, accountId]);
        continue;
      }

      await _syncRepo.upsertByRemoteId(
        table: 'categories',
        remoteId: doc.id,
        accountId: accountId,
        data: {
          'name': data['name'],
          'type': data['type'],
          'icon': data['icon'],
          'updated_at': data['updated_at'],
        },
      );
    }
  }

  /// Push deletes as tombstones (set deleted_at + updated_at, không xóa thật)
  /// Để device khác pull thấy deleted_at → xóa local.
  Future<void> _pushDeletes(String accountId) async {
    final deletes = await _syncRepo.getPendingDeletes(accountId);
    if (deletes.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final accountDoc = firestore.collection('accounts').doc(accountId);
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final d in deletes) {
      final table = d['table_name'] as String;
      final remoteId = d['remote_id'] as String;
      final docRef = accountDoc.collection(table).doc(remoteId);
      // Tombstone: giữ doc nhưng đánh dấu deleted_at
      batch.set(docRef, {
        'deleted_at': now,
        'updated_at': now,
      }, SetOptions(merge: true));
    }
    await batch.commit();

    final ids = deletes.map((d) => d['id'] as int).toList();
    await _syncRepo.clearPendingDeletes(ids);
  }

  /// Đếm records chưa sync
  Future<int> getDirtyCount(String accountId) async {
    return await _syncRepo.getDirtyCount(accountId);
  }

  /// Cleanup tombstones tối đa 1 lần/ngày per account
  Future<void> _maybeCleanupTombstones(String accountId) async {
    final key = 'sync_cleanup_$accountId';
    final lastStr = await _settingRepo.get(key);
    final lastCleanup = lastStr != null ? int.parse(lastStr) : 0;
    final oneDayAgo = DateTime.now()
        .subtract(const Duration(days: 1))
        .millisecondsSinceEpoch;

    if (lastCleanup > oneDayAgo) return; // đã cleanup hôm nay rồi

    await cleanupTombstones(accountId);
    await _settingRepo.set(key, DateTime.now().millisecondsSinceEpoch.toString());
  }

  /// #21 — Cleanup tombstones > 30 ngày trên Firestore
  Future<void> cleanupTombstones(String accountId) async {
    if (!await _hasNetwork) return;

    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;

    final firestore = FirebaseFirestore.instance;
    final accountDoc = firestore.collection('accounts').doc(accountId);

    for (final collection in ['wallets', 'transactions', 'categories']) {
      final query = accountDoc.collection(collection)
          .where('deleted_at', isLessThan: cutoff);
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) continue;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
