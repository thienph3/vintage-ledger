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
      final copy = wallet.copyWith(name: 'New');
      expect(copy.name, 'New');
      expect(copy.balance, 100);
      expect(copy.id, 1);
    });

    test('equality', () {
      final same = Wallet(id: 1, name: 'Test', balance: 100, createdAt: 1000);
      final diff = Wallet(id: 2, name: 'Test', balance: 100, createdAt: 1000);
      expect(wallet, same);
      expect(wallet, isNot(diff));
      expect(wallet.hashCode, same.hashCode);
    });

    test('fromMap handles string created_at fallback', () {
      final w = Wallet.fromMap({
        'id': 1,
        'name': 'X',
        'balance': 0,
        'created_at': '12345',
      });
      expect(w.createdAt, 12345);
    });
  });

  group('TransactionModel', () {
    final txn = TransactionModel(
      id: 1,
      walletId: 1,
      categoryId: 2,
      type: TransactionType.income,
      amount: 500,
      note: 'test',
      date: 2000,
    );

    test('toMap and fromMap roundtrip', () {
      final restored = TransactionModel.fromMap(txn.toMap());
      expect(restored, txn);
    });

    test('copyWith creates modified copy', () {
      final copy = txn.copyWith(amount: 999);
      expect(copy.amount, 999);
      expect(copy.type, TransactionType.income);
    });

    test('equality ignores note', () {
      final withNote = txn.copyWith(note: 'different');
      // note is not in == comparison
      expect(txn, withNote);
    });

    test('fromMap parses type string to enum', () {
      final map = txn.toMap();
      expect(map['type'], 'income');
      final restored = TransactionModel.fromMap(map);
      expect(restored.type, TransactionType.income);
    });
  });

  group('Category', () {
    final cat = Category(id: 1, name: 'Food', type: 'expense', icon: 0xe57a);

    test('toMap and fromMap roundtrip', () {
      final restored = Category.fromMap(cat.toMap());
      expect(restored, cat);
    });

    test('copyWith creates modified copy', () {
      final copy = cat.copyWith(name: 'Drink');
      expect(copy.name, 'Drink');
      expect(copy.type, 'expense');
    });

    test('equality', () {
      final same = Category(id: 1, name: 'Food', type: 'expense', icon: 0xe57a);
      expect(cat, same);
      expect(cat.hashCode, same.hashCode);
    });
  });
}
