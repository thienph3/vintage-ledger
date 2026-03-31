import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

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

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
  wallet_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  type TEXT,
  amount INTEGER,
  note TEXT,
  date INTEGER,
  FOREIGN KEY(wallet_id) REFERENCES wallets(id),
  FOREIGN KEY(category_id) REFERENCES categories(id)
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

    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_wallet ON transactions(wallet_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transaction_items_txn ON transaction_items(transaction_id)');
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      // Expense
      {'name': 'Ăn uống', 'type': 'expense', 'icon': kCategoryIcons[0].codePoint},
      {'name': 'Di chuyển', 'type': 'expense', 'icon': kCategoryIcons[1].codePoint},
      {'name': 'Mua sắm', 'type': 'expense', 'icon': kCategoryIcons[2].codePoint},
      {'name': 'Nhà ở', 'type': 'expense', 'icon': kCategoryIcons[3].codePoint},
      {'name': 'Sức khỏe', 'type': 'expense', 'icon': kCategoryIcons[4].codePoint},
      {'name': 'Giáo dục', 'type': 'expense', 'icon': kCategoryIcons[5].codePoint},
      {'name': 'Giải trí', 'type': 'expense', 'icon': kCategoryIcons[6].codePoint},
      {'name': 'Cà phê', 'type': 'expense', 'icon': kCategoryIcons[7].codePoint},
      {'name': 'Hóa đơn', 'type': 'expense', 'icon': kCategoryIcons[8].codePoint},
      {'name': 'Khác', 'type': 'expense', 'icon': kCategoryIcons[9].codePoint},
      // Income
      {'name': 'Lương', 'type': 'income', 'icon': kCategoryIcons[10].codePoint},
      {'name': 'Thưởng', 'type': 'income', 'icon': kCategoryIcons[11].codePoint},
      {'name': 'Đầu tư', 'type': 'income', 'icon': kCategoryIcons[12].codePoint},
      {'name': 'Khác', 'type': 'income', 'icon': kCategoryIcons[9].codePoint},
    ];

    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', c);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createIndexes(db);
    }
  }

  /// Tính lại balance của wallet từ tổng transactions.
  Future<void> recalculateBalance(int walletId) async {
    final db = await database;
    await db.transaction((txn) async {
      final result = await txn.rawQuery('''
        SELECT
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) as income,
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as expense
        FROM transactions WHERE wallet_id = ?
      ''', [walletId]);

      final income = result.first['income'] as int;
      final expense = result.first['expense'] as int;

      await txn.update(
        'wallets',
        {'balance': income - expense},
        where: 'id = ?',
        whereArgs: [walletId],
      );
    });
  }
}
