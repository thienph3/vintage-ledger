import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/category.dart';

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
  Future<List<Category>> getAll() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'categories',
      orderBy: 'name ASC',
    );

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
  Future<List<Category>> getByType(String type) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'name ASC',
    );

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

    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}