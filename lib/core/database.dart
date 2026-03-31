import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();

  static Database? _database;

  AppDatabase._init();

  static void resetForTest() {
    _database = null;
  }

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
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
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
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  account_id TEXT NOT NULL DEFAULT 'local',
  is_synced INTEGER NOT NULL DEFAULT 1,
  remote_id TEXT
)
''');

    await db.execute('''
CREATE TABLE categories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT,
  icon INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER,
  account_id TEXT NOT NULL DEFAULT 'local',
  is_synced INTEGER NOT NULL DEFAULT 1,
  remote_id TEXT
)
''');

    await _seedCategories(db);

    await db.execute('''
CREATE TABLE transactions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wallet_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
  amount INTEGER NOT NULL CHECK(amount > 0),
  note TEXT,
  date INTEGER NOT NULL,
  updated_at INTEGER,
  account_id TEXT NOT NULL DEFAULT 'local',
  is_synced INTEGER NOT NULL DEFAULT 1,
  remote_id TEXT,
  created_by TEXT,
  FOREIGN KEY(wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
  FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT
)
''');

    await db.execute('''
CREATE TABLE transaction_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  amount INTEGER NOT NULL CHECK(amount > 0),
  category_id INTEGER,
  note TEXT,
  FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE sync_deletes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  remote_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  deleted_at INTEGER NOT NULL
)
''');

    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_transactions_wallet ON transactions(wallet_id)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transaction_items_txn ON transaction_items(transaction_id)');
    await db.execute('CREATE INDEX idx_wallets_account_sync ON wallets(account_id, is_synced)');
    await db.execute('CREATE INDEX idx_transactions_account_sync ON transactions(account_id, is_synced)');
    await db.execute('CREATE INDEX idx_categories_account_sync ON categories(account_id, is_synced)');
  }

  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final categories = [
      {'name': 'Ăn uống', 'type': 'expense', 'icon': kCategoryIcons[0].codePoint, 'created_at': now},
      {'name': 'Di chuyển', 'type': 'expense', 'icon': kCategoryIcons[1].codePoint, 'created_at': now},
      {'name': 'Mua sắm', 'type': 'expense', 'icon': kCategoryIcons[2].codePoint, 'created_at': now},
      {'name': 'Nhà ở', 'type': 'expense', 'icon': kCategoryIcons[3].codePoint, 'created_at': now},
      {'name': 'Sức khỏe', 'type': 'expense', 'icon': kCategoryIcons[4].codePoint, 'created_at': now},
      {'name': 'Giáo dục', 'type': 'expense', 'icon': kCategoryIcons[5].codePoint, 'created_at': now},
      {'name': 'Giải trí', 'type': 'expense', 'icon': kCategoryIcons[6].codePoint, 'created_at': now},
      {'name': 'Cà phê', 'type': 'expense', 'icon': kCategoryIcons[7].codePoint, 'created_at': now},
      {'name': 'Hóa đơn', 'type': 'expense', 'icon': kCategoryIcons[8].codePoint, 'created_at': now},
      {'name': 'Khác', 'type': 'expense', 'icon': kCategoryIcons[9].codePoint, 'created_at': now},
      {'name': 'Lương', 'type': 'income', 'icon': kCategoryIcons[10].codePoint, 'created_at': now},
      {'name': 'Thưởng', 'type': 'income', 'icon': kCategoryIcons[11].codePoint, 'created_at': now},
      {'name': 'Đầu tư', 'type': 'income', 'icon': kCategoryIcons[12].codePoint, 'created_at': now},
      {'name': 'Khác', 'type': 'income', 'icon': kCategoryIcons[9].codePoint, 'created_at': now},
    ];

    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', c);
    }
    await batch.commit(noResult: true);
  }

  Future<void> migrateLocalDataToAccount(String accountId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate("UPDATE wallets SET account_id = ? WHERE account_id = 'local'", [accountId]);
      await txn.rawUpdate("UPDATE transactions SET account_id = ? WHERE account_id = 'local'", [accountId]);
      await txn.rawUpdate("UPDATE categories SET account_id = ? WHERE account_id = 'local'", [accountId]);
    });
  }

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
