import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

void main() {
  group('Wallet', () {
    final wallet = Wallet(id: 1, name: 'Test', balance: 100, createdAt: 1000);

    test('toMap and fromMap roundtrip', () {
      final restored = Wallet.fromMap(wallet.toMap());
      expect(restored, wallet);
    });

    test('copyWith creates modified copy', () {
      final copy = wallet.copyWith(name: 'New', accountId: 'acc1');
      expect(copy.name, 'New');
      expect(copy.balance, 100);
      expect(copy.accountId, 'acc1');
    });

    test('equality', () {
      final same = Wallet(id: 1, name: 'Test', balance: 100, createdAt: 1000);
      final diff = Wallet(id: 2, name: 'Test', balance: 100, createdAt: 1000);
      expect(wallet, same);
      expect(wallet, isNot(diff));
    });

    test('sync fields default values', () {
      expect(wallet.accountId, 'local');
      expect(wallet.isSynced, 1);
      expect(wallet.remoteId, null);
      expect(wallet.isDirty, false);
    });

    test('isDirty when isSynced = 0', () {
      final dirty = wallet.copyWith(isSynced: 0);
      expect(dirty.isDirty, true);
    });
  });

  group('TransactionModel', () {
    final txn = TransactionModel(
      id: 1, walletId: 1, categoryId: 2,
      type: TransactionType.income, amount: 500, note: 'test', date: 2000,
    );

    test('toMap and fromMap roundtrip', () {
      final restored = TransactionModel.fromMap(txn.toMap());
      expect(restored, txn);
    });

    test('copyWith with sync fields', () {
      final copy = txn.copyWith(accountId: 'acc1', remoteId: 'r1', createdBy: 'u1');
      expect(copy.accountId, 'acc1');
      expect(copy.remoteId, 'r1');
      expect(copy.createdBy, 'u1');
    });

    test('sync fields default values', () {
      expect(txn.accountId, 'local');
      expect(txn.isSynced, 1);
      expect(txn.remoteId, null);
      expect(txn.createdBy, null);
    });
  });

  group('Category', () {
    final cat = Category(id: 1, name: 'Food', type: TransactionType.expense, icon: 0xe57a);

    test('toMap and fromMap roundtrip', () {
      final restored = Category.fromMap(cat.toMap());
      expect(restored, cat);
    });

    test('copyWith with sync fields', () {
      final copy = cat.copyWith(accountId: 'acc1', remoteId: 'r1');
      expect(copy.accountId, 'acc1');
      expect(copy.remoteId, 'r1');
    });

    test('sync fields default values', () {
      expect(cat.accountId, 'local');
      expect(cat.isSynced, 1);
      expect(cat.isDirty, false);
    });
  });
}
