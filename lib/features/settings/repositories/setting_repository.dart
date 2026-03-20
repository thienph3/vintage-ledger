import 'package:sqflite/sqflite.dart';
import 'package:vintage_ledger/core/database.dart';

class SettingRepository {
  Future<String?> get(String key) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (result.isNotEmpty) return result.first['value'] as String;
    return null;
  }

  Future<void> set(String key, String value) async {
    final db = await AppDatabase.instance.database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
