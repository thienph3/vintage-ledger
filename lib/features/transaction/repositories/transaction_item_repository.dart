import 'package:sqflite/sqflite.dart';
import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';

class TransactionItemRepository {
  /// CREATE
  Future<int> create(TransactionItemModel item) async {
    final db = await AppDatabase.instance.database;

    // Validate tổng amount không vượt quá parent transaction
    final parent = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [item.transactionId],
      limit: 1,
    );

    if (parent.isEmpty) {
      throw Exception('Parent transaction not found');
    }

    final transaction = TransactionModel.fromMap(parent.first);

    final totalItemAmountResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transaction_items WHERE transaction_id = ?',
      [item.transactionId],
    );

    final totalItemAmount = totalItemAmountResult.first['total'] != null
        ? int.parse(totalItemAmountResult.first['total'].toString())
        : 0;

    if (totalItemAmount + item.amount > transaction.amount) {
      throw Exception('Item amount exceeds parent transaction total');
    }

    return await db.insert(
      'transaction_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ ALL ITEMS
  Future<List<TransactionItemModel>> getAll() async {
    final db = await AppDatabase.instance.database;

    final result = await db.query('transaction_items', orderBy: 'id ASC');

    return result.map((e) => TransactionItemModel.fromMap(e)).toList();
  }

  /// READ BY ID
  Future<TransactionItemModel?> getById(int id) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'transaction_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return TransactionItemModel.fromMap(result.first);
    }
    return null;
  }

  /// READ BY TRANSACTION
  Future<List<TransactionItemModel>> getByTransaction(int transactionId) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      orderBy: 'id ASC',
    );

    return result.map((e) => TransactionItemModel.fromMap(e)).toList();
  }

  /// UPDATE
  Future<int> update(TransactionItemModel item) async {
    final db = await AppDatabase.instance.database;

    // Kiểm tra tổng amount sau khi update
    final parentResult = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [item.transactionId],
      limit: 1,
    );

    if (parentResult.isEmpty) {
      throw Exception('Parent transaction not found');
    }

    final transaction = TransactionModel.fromMap(parentResult.first);

    final totalItemAmountResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transaction_items WHERE transaction_id = ? AND id != ?',
      [item.transactionId, item.id],
    );

    final totalItemAmount = totalItemAmountResult.first['total'] != null
        ? int.parse(totalItemAmountResult.first['total'].toString())
        : 0;

    if (totalItemAmount + item.amount > transaction.amount) {
      throw Exception('Item amount exceeds parent transaction total');
    }

    return await db.update(
      'transaction_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// DELETE
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;

    return await db.delete(
      'transaction_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
