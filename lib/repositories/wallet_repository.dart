import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/wallet.dart';

class WalletRepository {

  /// CREATE
  Future<int> create(Wallet wallet) async {
    final db = await AppDatabase.instance.database;

    return await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ ALL
  Future<List<Wallet>> getAll() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'wallets',
      orderBy: 'created_at DESC',
    );

    return result.map((e) => Wallet.fromMap(e)).toList();
  }

  /// READ BY ID
  Future<Wallet?> getById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Wallet.fromMap(result.first);
    }

    return null;
  }

  /// UPDATE
  Future<int> update(Wallet wallet) async {
    final db = await AppDatabase.instance.database;

    return await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  /// DELETE
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}