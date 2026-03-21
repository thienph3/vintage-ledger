import 'dart:math';

import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';

class SampleDataService {
  final _walletService = WalletService();
  final _txnService = TransactionService();
  final _catService = CategoryService();

  Future<void> generate() async {
    final walletId = await _walletService.createWallet('Ví chính', 0);

    final cats = await _catService.getCategories();
    final expenseCats = cats.where((c) => c.type == 'expense').toList();
    final incomeCats = cats.where((c) => c.type == 'income').toList();

    if (expenseCats.isEmpty || incomeCats.isEmpty) return;

    final rng = Random(42);
    final now = DateTime.now();

    // Generate ~30 days of transactions
    for (var d = 29; d >= 0; d--) {
      final day = now.subtract(Duration(days: d));

      // 1-2 income per week (on ~Mon/Fri)
      if (day.weekday == DateTime.monday || day.weekday == DateTime.friday) {
        final cat = incomeCats[rng.nextInt(incomeCats.length)];
        final amount = (rng.nextInt(10) + 5) * 100000; // 500k-1.4m
        final date = DateTime(day.year, day.month, day.day, 8 + rng.nextInt(3));
        await _txnService.createTransaction(
          walletId: walletId,
          categoryId: cat.id!,
          type: 'income',
          amount: amount,
          date: date.millisecondsSinceEpoch,
        );
      }

      // 1-3 expenses per day
      final expCount = rng.nextInt(3) + 1;
      for (var i = 0; i < expCount; i++) {
        final cat = expenseCats[rng.nextInt(expenseCats.length)];
        final amount = (rng.nextInt(15) + 1) * 10000; // 10k-150k
        final hour = 7 + rng.nextInt(14);
        final date = DateTime(day.year, day.month, day.day, hour, rng.nextInt(60));
        await _txnService.createTransaction(
          walletId: walletId,
          categoryId: cat.id!,
          type: 'expense',
          amount: amount,
          date: date.millisecondsSinceEpoch,
        );
      }
    }
  }
}
