import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/database.dart';

class SyncRepository {
  final _firestore = FirebaseFirestore.instance;

  DocumentReference _accountDoc(String accountId) =>
      _firestore.collection('accounts').doc(accountId);

  // ── Push ──

  /// Push dirty records. Returns list of {localId, remoteId} for new records.
  Future<List<Map<String, dynamic>>> pushRecords({
    required String accountId,
    required String collection,
    required List<Map<String, dynamic>> records,
  }) async {
    final col = _accountDoc(accountId).collection(collection);
    final newMappings = <Map<String, dynamic>>[];

    // Separate new vs existing
    final toUpdate = <Map<String, dynamic>>[];
    final toCreate = <Map<String, dynamic>>[];

    for (final record in records) {
      final remoteId = record['remote_id'] as String?;
      if (remoteId != null && remoteId.isNotEmpty) {
        toUpdate.add(record);
      } else {
        toCreate.add(record);
      }
    }

    // Batch update existing records
    if (toUpdate.isNotEmpty) {
      final batch = _firestore.batch();
      for (final record in toUpdate) {
        batch.update(
          col.doc(record['remote_id'] as String),
          record['data'] as Map<String, dynamic>,
        );
      }
      await batch.commit();
    }

    // Individual add for new records (need doc ID back)
    for (final record in toCreate) {
      final docRef = await col.add(record['data'] as Map<String, dynamic>);
      newMappings.add({
        'local_id': record['local_id'],
        'remote_id': docRef.id,
      });
    }

    return newMappings;
  }

  // ── Pull ──

  Future<List<QueryDocumentSnapshot>> pullRecords({
    required String accountId,
    required String collection,
    required int lastPullAt,
  }) async {
    final query = _accountDoc(accountId)
        .collection(collection)
        .where('updated_at', isGreaterThan: lastPullAt);
    final snapshot = await query.get();
    return snapshot.docs;
  }

  // ── Dirty records from SQLite ──

  Future<List<Map<String, dynamic>>> getDirtyWallets(String accountId) async {
    final db = await AppDatabase.instance.database;
    return await db.query('wallets',
        where: 'account_id = ? AND is_synced = 0', whereArgs: [accountId]);
  }

  Future<List<Map<String, dynamic>>> getDirtyTransactions(String accountId) async {
    final db = await AppDatabase.instance.database;
    return await db.query('transactions',
        where: 'account_id = ? AND is_synced = 0', whereArgs: [accountId]);
  }

  Future<List<Map<String, dynamic>>> getDirtyCategories(String accountId) async {
    final db = await AppDatabase.instance.database;
    return await db.query('categories',
        where: 'account_id = ? AND is_synced = 0', whereArgs: [accountId]);
  }

  // ── Mark synced ──

  Future<void> markSynced(String table, List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE $table SET is_synced = 1 WHERE id IN ($placeholders)', ids,
    );
  }

  Future<void> setRemoteId(String table, int localId, String remoteId) async {
    final db = await AppDatabase.instance.database;
    await db.update(table, {'remote_id': remoteId, 'is_synced': 1},
        where: 'id = ?', whereArgs: [localId]);
  }

  // ── Upsert helpers (Pull) ──

  /// Upsert 1 record vào SQLite by remote_id. Returns local id, or -1 if skipped (local newer).
  Future<int> upsertByRemoteId({
    required String table,
    required String remoteId,
    required String accountId,
    required Map<String, dynamic> data,
  }) async {
    final db = await AppDatabase.instance.database;

    final existing = await db.query(table,
        where: 'remote_id = ? AND account_id = ?',
        whereArgs: [remoteId, accountId],
        limit: 1);

    final row = Map<String, dynamic>.from(data);
    row['remote_id'] = remoteId;
    row['account_id'] = accountId;
    row['is_synced'] = 1;

    if (existing.isNotEmpty) {
      final localId = existing.first['id'] as int;
      final localUpdatedAt = existing.first['updated_at'] as int? ?? 0;
      final remoteUpdatedAt = data['updated_at'] as int? ?? 0;

      // #18 Last-write-wins: local newer → skip, keep local dirty
      if (localUpdatedAt > remoteUpdatedAt && existing.first['is_synced'] == 0) {
        return -1;
      }

      await db.update(table, row, where: 'id = ?', whereArgs: [localId]);
      return localId;
    } else {
      return await db.insert(table, row);
    }
  }

  /// Upsert transaction items (delete old + insert new)
  Future<void> upsertTransactionItems(int transactionId, List<dynamic> items) async {
    final db = await AppDatabase.instance.database;
    await db.delete('transaction_items',
        where: 'transaction_id = ?', whereArgs: [transactionId]);
    for (final item in items) {
      final m = item as Map<String, dynamic>;
      await db.insert('transaction_items', {
        'transaction_id': transactionId,
        'amount': m['amount'],
        'note': m['note'],
        'category_id': m['category_id'],
      });
    }
  }

  // ── Dirty count ──

  Future<int> getDirtyCount(String accountId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM wallets WHERE account_id = ? AND is_synced = 0) +
        (SELECT COUNT(*) FROM transactions WHERE account_id = ? AND is_synced = 0) +
        (SELECT COUNT(*) FROM categories WHERE account_id = ? AND is_synced = 0) +
        (SELECT COUNT(*) FROM sync_deletes WHERE account_id = ?)
        AS total
    ''', [accountId, accountId, accountId, accountId]);
    return result.first['total'] as int;
  }

  // ── Delete log ──

  Future<List<Map<String, dynamic>>> getPendingDeletes(String accountId) async {
    final db = await AppDatabase.instance.database;
    return await db.query('sync_deletes',
        where: 'account_id = ?', whereArgs: [accountId]);
  }

  Future<void> clearPendingDeletes(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawDelete('DELETE FROM sync_deletes WHERE id IN ($placeholders)', ids);
  }
}
