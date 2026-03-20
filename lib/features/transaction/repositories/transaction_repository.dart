import 'package:sqflite/sqflite.dart';
import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';

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

  /// READ RECENT (with optional wallet filter)
  Future<List<TransactionModel>> getRecent(int limit, {int? walletId}) async {
    final db = await AppDatabase.instance.database;

    return (await db.query(
      'transactions',
      where: walletId != null ? 'wallet_id = ?' : null,
      whereArgs: walletId != null ? [walletId] : null,
      orderBy: 'date DESC',
      limit: limit,
    )).map((e) => TransactionModel.fromMap(e)).toList();
  }

  /// READ BY DATE RANGE (with optional wallet filter)
  Future<List<TransactionModel>> getByDateRange(
    int startDate,
    int endDate, {
    int? walletId,
  }) async {
    final db = await AppDatabase.instance.database;

    final where = walletId != null
        ? 'date >= ? AND date <= ? AND wallet_id = ?'
        : 'date >= ? AND date <= ?';
    final whereArgs = walletId != null
        ? [startDate, endDate, walletId]
        : [startDate, endDate];

    return (await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    )).map((e) => TransactionModel.fromMap(e)).toList();
  }

  /// DELETE ALL TRANSACTIONS FOR A WALLET
  Future<void> deleteAllByWallet(int walletId) async {
    final db = await AppDatabase.instance.database;

    // Delete items first
    await db.rawDelete(
      'DELETE FROM transaction_items WHERE transaction_id IN '
      '(SELECT id FROM transactions WHERE wallet_id = ?)',
      [walletId],
    );

    await db.delete('transactions', where: 'wallet_id = ?', whereArgs: [walletId]);
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

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
