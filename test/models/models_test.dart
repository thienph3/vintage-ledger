import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

void main() {
  group('Wallet', () {
    test('constructor defaults', () {
      final w = Wallet(name: 'Test');
      expect(w.balance, 0);
      expect(w.currency, 'VND');
      expect(w.id, isNull);
    });

    test('copyWith', () {
      final w = Wallet(id: 'w1', name: 'A', balance: 100, currency: 'USD');
      final w2 = w.copyWith(name: 'B');
      expect(w2.name, 'B');
      expect(w2.balance, 100);
      expect(w2.currency, 'USD');
    });

    test('equality', () {
      final a = Wallet(id: 'w1', name: 'A', balance: 100, currency: 'VND');
      final b = Wallet(id: 'w1', name: 'A', balance: 100, currency: 'VND');
      expect(a, equals(b));
    });
  });

  group('TransactionModel', () {
    test('constructor', () {
      final t = TransactionModel(
        walletId: 'w1', categoryId: 'c1',
        type: TransactionType.expense, amount: 50000, date: 1000,
      );
      expect(t.type.isExpense, true);
      expect(t.createdBy, isNull);
    });

    test('copyWith', () {
      final t = TransactionModel(
        id: 't1', walletId: 'w1', categoryId: 'c1',
        type: TransactionType.income, amount: 100000, date: 2000,
      );
      final t2 = t.copyWith(amount: 200000);
      expect(t2.amount, 200000);
      expect(t2.type, TransactionType.income);
    });
  });

  group('Category', () {
    test('constructor', () {
      final c = Category(name: 'Food', type: TransactionType.expense);
      expect(c.icon, isNull);
      expect(c.id, isNull);
    });

    test('equality', () {
      final a = Category(id: 'c1', name: 'Food', type: TransactionType.expense, icon: 100);
      final b = Category(id: 'c1', name: 'Food', type: TransactionType.expense, icon: 100);
      expect(a, equals(b));
    });
  });
}
