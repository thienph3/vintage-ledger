import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/database.dart';

class SyncRepository {
  final _firestore = FirebaseFirestore.instance;

  DocumentReference _accountDoc(String accountId) =>
      _firestore.collection('accounts').doc(accountId);

  // ── Push helpers ──

  Future<void> pushRecords({
    required String accountId,
    required String collection,
    required List<Map<String, dynamic>> records,
  }) async {
    final batch = _firestore.batch();
    final col = _accountDoc(accountId).collection(collection);

    for (final record in records) {
      final remoteId = record['remote_id'] as String?;
      if (remoteId != null && remoteId.isNotEmpty) {
        batch.update(col.doc(remoteId), record['data'] as Map<String, dynamic>);
      } else {
        batch.set(col.doc(), record['data'] as Map<String, dynamic>);
      }
    }
    await batch.commit();
  }

  // ── Pull helpers ──

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

  // ── Update remote_id after first push ──

  Future<void> setRemoteId(String table, int localId, String remoteId) async {
    final db = await AppDatabase.instance.database;
    await db.update(table, {'remote_id': remoteId},
        where: 'id = ?', whereArgs: [localId]);
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
