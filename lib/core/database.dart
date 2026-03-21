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

    await _seedCategories(db);

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

  Future<void> _seedCategories(Database db) async {
    const categories = [
      // Expense
      {'name': 'Ăn uống', 'type': 'expense', 'icon': 0xe25a},      // fastfood
      {'name': 'Di chuyển', 'type': 'expense', 'icon': 0xe1d7},    // directions_car
      {'name': 'Mua sắm', 'type': 'expense', 'icon': 0xe8cc},      // shopping_cart
      {'name': 'Nhà ở', 'type': 'expense', 'icon': 0xe318},        // home
      {'name': 'Sức khỏe', 'type': 'expense', 'icon': 0xe8e8},     // health_and_safety
      {'name': 'Giáo dục', 'type': 'expense', 'icon': 0xe80c},     // school
      {'name': 'Giải trí', 'type': 'expense', 'icon': 0xe02c},     // movie
      {'name': 'Cà phê', 'type': 'expense', 'icon': 0xe541},       // local_cafe
      {'name': 'Hóa đơn', 'type': 'expense', 'icon': 0xe873},      // receipt_long
      {'name': 'Khác', 'type': 'expense', 'icon': 0xe5d3},         // more_horiz
      // Income
      {'name': 'Lương', 'type': 'income', 'icon': 0xe850},         // account_balance_wallet
      {'name': 'Thưởng', 'type': 'income', 'icon': 0xe8f6},        // star
      {'name': 'Đầu tư', 'type': 'income', 'icon': 0xe8e5},        // trending_up
      {'name': 'Khác', 'type': 'income', 'icon': 0xe5d3},          // more_horiz
    ];

    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', c);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}
}
