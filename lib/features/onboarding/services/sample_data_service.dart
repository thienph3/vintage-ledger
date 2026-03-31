import 'dart:math';

import 'package:vintage_ledger/core/database.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class SampleDataService {
  Future<void> generate() async {
    final walletId = await sl.walletService.createWallet('Ví chính', 0);

    final cats = await sl.categoryService.getCategories();
    final expenseCats = cats.where((c) => c.type == TransactionType.expense).toList();
    final incomeCats = cats.where((c) => c.type == TransactionType.income).toList();

    if (expenseCats.isEmpty || incomeCats.isEmpty) return;

    final rng = Random(42);
    final now = DateTime.now();

    final rows = <Map<String, dynamic>>[];
    int balance = 0;

    for (var d = 29; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));

      if (day.weekday == DateTime.monday || day.weekday == DateTime.friday) {
        final cat = incomeCats[rng.nextInt(incomeCats.length)];
        final amount = (rng.nextInt(10) + 5) * 100000;
        final date = DateTime(day.year, day.month, day.day, 8 + rng.nextInt(3));
        rows.add({
          'wallet_id': walletId,
          'category_id': cat.id!,
          'type': TransactionType.income.value,
          'amount': amount,
          'date': date.millisecondsSinceEpoch,
        });
        balance += amount;
      }

      final expCount = rng.nextInt(3) + 1;
      for (var i = 0; i < expCount; i++) {
        final cat = expenseCats[rng.nextInt(expenseCats.length)];
        final amount = (rng.nextInt(15) + 1) * 10000;
        final hour = 7 + rng.nextInt(14);
        final date = DateTime(day.year, day.month, day.day, hour, rng.nextInt(60));
        rows.add({
          'wallet_id': walletId,
          'category_id': cat.id!,
          'type': TransactionType.expense.value,
          'amount': amount,
          'date': date.millisecondsSinceEpoch,
        });
        balance -= amount;
      }
    }

    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert('transactions', row);
      }
      await batch.commit(noResult: true);

      await txn.update(
        'wallets',
        {'balance': balance},
        where: 'id = ?',
        whereArgs: [walletId],
      );
    });
  }
}
