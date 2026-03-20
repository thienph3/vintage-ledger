import 'package:sqflite/sqflite.dart';
import '../database.dart';
import '../models/transaction.dart';

class TransactionRepository {

  /// CREATE
  Future<int> create(TransactionModel transaction) async {
    final db = await AppDatabase.instance.database;

    return await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ ALL
  Future<List<TransactionModel>> getAll() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  /// READ BY ID
  Future<TransactionModel?> getById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return TransactionModel.fromMap(result.first);
    }

    return null;
  }

  /// READ BY WALLET
  Future<List<TransactionModel>> getByWallet(int walletId) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'transactions',
      where: 'wallet_id = ?',
      whereArgs: [walletId],
      orderBy: 'date DESC',
    );

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  /// UPDATE
  Future<int> update(TransactionModel transaction) async {
    final db = await AppDatabase.instance.database;

    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// DELETE
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}