import 'package:sqflite/sqflite.dart';
import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class CategoryRepository {
  /// CREATE
  Future<int> create(Category category) async {
    final db = await AppDatabase.instance.database;
    final map = category.toMap();
    map['is_synced'] = 0;
    return await db.insert('categories', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// READ ALL
  Future<List<Category>> getAll({String accountId = 'local'}) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('categories',
        where: 'account_id = ?', whereArgs: [accountId], orderBy: 'name ASC');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  /// READ BY ID
  Future<Category?> getById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }

    return null;
  }

  /// READ BY TYPE (income / expense)
  Future<List<Category>> getByType(String type, {String accountId = 'local'}) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('categories',
        where: 'type = ? AND account_id = ?', whereArgs: [type, accountId], orderBy: 'name ASC');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  /// UPDATE
  Future<int> update(Category category) async {
    final db = await AppDatabase.instance.database;
    final map = category.toMap();
    map['is_synced'] = 0;
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update('categories', map, where: 'id = ?', whereArgs: [category.id]);
  }

  /// DELETE (ghi sync_deletes trước khi xóa)
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await _logDeleteForSync(db, 'categories', id);
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
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
