import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

  /// Set to true to wipe and recreate DB on next launch.
  static const _resetOnInit = false;

  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('wallet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    if (_resetOnInit) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE settings(
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE wallets(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  balance INTEGER NOT NULL DEFAULT 0,
  created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE categories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT,
  icon INTEGER
)
''');

    await db.execute('''
CREATE TABLE transactions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wallet_id INTEGER,
  category_id INTEGER,
  type TEXT,
  amount INTEGER,
  note TEXT,
  date TEXT
)
''');

    await db.execute('''
CREATE TABLE transaction_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  category_id INTEGER,
  note TEXT,
  FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
)
''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}
}
