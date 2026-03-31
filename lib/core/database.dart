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
      version: 6,
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

    await _createIndexes(db);
    await _createSyncDeletesTable(db);
  }

  Future<void> _createSyncDeletesTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS sync_deletes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  remote_id TEXT NOT NULL,
  account_id TEXT NOT NULL,
  deleted_at INTEGER NOT NULL
)
''');
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
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
    if (oldVersion < 5) {
      await _migrateToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
  }

  Future<void> _migrateToV6(Database db) async {
    await db.execute('ALTER TABLE wallets ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE wallets ADD COLUMN remote_id TEXT');
    await db.execute('ALTER TABLE transactions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE transactions ADD COLUMN remote_id TEXT');
    await db.execute('ALTER TABLE transactions ADD COLUMN created_by TEXT');
    await db.execute('ALTER TABLE categories ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1');
    await db.execute('ALTER TABLE categories ADD COLUMN remote_id TEXT');
    await _createSyncDeletesTable(db);
  }

  Future<void> _migrateToV5(Database db) async {
    await db.execute("ALTER TABLE wallets ADD COLUMN account_id TEXT NOT NULL DEFAULT 'local'");
    await db.execute("ALTER TABLE transactions ADD COLUMN account_id TEXT NOT NULL DEFAULT 'local'");
    await db.execute("ALTER TABLE categories ADD COLUMN account_id TEXT NOT NULL DEFAULT 'local'");
  }

  Future<void> _migrateToV4(Database db) async {
    await db.execute('ALTER TABLE wallets ADD COLUMN updated_at INTEGER');
    await db.execute('ALTER TABLE transactions ADD COLUMN updated_at INTEGER');
  }

  /// V3 migration: recreate wallets (created_at → INTEGER) and transactions
  /// (ON DELETE CASCADE/RESTRICT, CHECK constraints).
  Future<void> _migrateToV3(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');

    await db.transaction((txn) async {
      // ── Migrate wallets: created_at TEXT → INTEGER ──
      await txn.execute('ALTER TABLE wallets RENAME TO wallets_old');
      await txn.execute('''
CREATE TABLE wallets(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  balance INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)
''');
      // Convert ISO string to epoch, fallback to 0
      await txn.execute('''
INSERT INTO wallets(id, name, balance, created_at)
SELECT id, name, balance,
  CASE
    WHEN created_at IS NOT NULL AND created_at != ''
    THEN CAST(strftime('%s', created_at) AS INTEGER) * 1000
    ELSE 0
  END
FROM wallets_old
''');
      await txn.execute('DROP TABLE wallets_old');

      // ── Migrate transactions: add FK actions + CHECK constraints ──
      await txn.execute('ALTER TABLE transactions RENAME TO transactions_old');
      await txn.execute('''
CREATE TABLE transactions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wallet_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
  amount INTEGER NOT NULL CHECK(amount > 0),
  note TEXT,
  date INTEGER NOT NULL,
  FOREIGN KEY(wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
  FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT
)
''');
      await txn.execute('''
INSERT INTO transactions(id, wallet_id, category_id, type, amount, note, date)
SELECT id, wallet_id, category_id, type, amount, note, date
FROM transactions_old
''');
      await txn.execute('DROP TABLE transactions_old');

      // Recreate indexes
      await _createIndexes(txn as Database);
    });

    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Migrate local data sang account khi login lần đầu
  Future<void> migrateLocalDataToAccount(String accountId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate("UPDATE wallets SET account_id = ? WHERE account_id = 'local'", [accountId]);
      await txn.rawUpdate("UPDATE transactions SET account_id = ? WHERE account_id = 'local'", [accountId]);
      await txn.rawUpdate("UPDATE categories SET account_id = ? WHERE account_id = 'local'", [accountId]);
    });
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
