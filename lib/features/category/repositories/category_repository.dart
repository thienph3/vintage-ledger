import 'package:sqflite/sqflite.dart';
import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class CategoryRepository {
  /// CREATE
  Future<int> create(Category category) async {
    final db = await AppDatabase.instance.database;

    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// DELETE
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
