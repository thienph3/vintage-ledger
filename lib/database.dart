import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {

    await db.execute('''
CREATE TABLE wallets(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  balance INTEGER,
  created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE categories(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT
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

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1️⃣ Thêm cột balance cho wallets
      await db.execute(
        "ALTER TABLE wallets ADD COLUMN balance INTEGER NOT NULL DEFAULT 0"
      );
    }

    if (oldVersion < 3) {
      // 2️⃣ Tạo bảng transaction_items
      await db.execute('''
        CREATE TABLE transaction_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          amount INTEGER NOT NULL,
          category_id INTEGER,
          note TEXT,
          FOREIGN KEY(transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 5) {
      // 1️⃣ Thêm cột icon cho categories
      await db.execute(
        "ALTER TABLE categories ADD COLUMN icon INTEGER"
      );
    }
  }
}