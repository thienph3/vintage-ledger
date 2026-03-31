import 'package:sqflite/sqflite.dart';
import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';

class WalletRepository {
  /// CREATE
  Future<int> create(Wallet wallet) async {
    final db = await AppDatabase.instance.database;
    final map = wallet.toMap();
    map['is_synced'] = 0;
    return await db.insert('wallets', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// READ ALL
  Future<List<Wallet>> getAll({String accountId = 'local'}) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('wallets',
        where: 'account_id = ?', whereArgs: [accountId], orderBy: 'created_at DESC');
    return result.map((e) => Wallet.fromMap(e)).toList();
  }

  /// READ BY ID
  Future<Wallet?> getById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Wallet.fromMap(result.first);
    }

    return null;
  }

  /// UPDATE
  Future<int> update(Wallet wallet, {int? updatedAt}) async {
    final db = await AppDatabase.instance.database;
    final map = wallet.toMap();
    map['is_synced'] = 0;
    if (updatedAt != null) map['updated_at'] = updatedAt;
    return await db.update('wallets', map, where: 'id = ?', whereArgs: [wallet.id]);
  }

  /// DELETE (ghi sync_deletes trước khi xóa)
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await _logDeleteForSync(db, 'wallets', id);
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _logDeleteForSync(Database db, String table, int id) async {
    final record = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (record.isEmpty) return;
    final remoteId = record.first['remote_id'] as String?;
    if (remoteId == null || remoteId.isEmpty) return;
    await db.insert('sync_deletes', {
      'table_name': table,
      'remote_id': remoteId,
      'account_id': record.first['account_id'],
      'deleted_at': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
