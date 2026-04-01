import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/quick_add/quick_add_parser.dart';

void main() {
  final categories = [
    Category(id: 'cat1', name: 'Ăn uống', type: TransactionType.expense),
    Category(id: 'cat2', name: 'Cà phê', type: TransactionType.expense),
    Category(id: 'cat3', name: 'Di chuyển', type: TransactionType.expense),
    Category(id: 'cat4', name: 'Mua sắm', type: TransactionType.expense),
    Category(id: 'cat5', name: 'Lương', type: TransactionType.income),
    Category(id: 'cat6', name: 'Thưởng', type: TransactionType.income),
  ];

  group('Amount parsing', () {
    test('50k → 50000', () {
      final r = QuickAddParser.parse('ăn sáng 50k', categories);
      expect(r.amount, 50000);
    });

    test('10tr → 10000000', () {
      final r = QuickAddParser.parse('lương 10tr', categories);
      expect(r.amount, 10000000);
    });

    test('1.5tr → 1500000', () {
      final r = QuickAddParser.parse('thưởng 1.5tr', categories);
      expect(r.amount, 1500000);
    });

    test('50000 → 50000', () {
      final r = QuickAddParser.parse('cf 50000', categories);
      expect(r.amount, 50000);
    });

    test('30 → 30', () {
      final r = QuickAddParser.parse('cf 30', categories);
      expect(r.amount, 30);
    });

    test('2 tỷ → 2000000000', () {
      final r = QuickAddParser.parse('2 tỷ', categories);
      expect(r.amount, 2000000000);
    });

    test('empty → 0', () {
      final r = QuickAddParser.parse('', categories);
      expect(r.amount, 0);
    });
  });

  group('Category matching', () {
    test('ăn sáng → Ăn uống', () {
      final r = QuickAddParser.parse('ăn sáng 50k', categories);
      expect(r.matchedCategoryId, 'cat1');
      expect(r.type, TransactionType.expense);
    });

    test('cf → Cà phê', () {
      final r = QuickAddParser.parse('cf 30k', categories);
      expect(r.matchedCategoryId, 'cat2');
    });

    test('grab → Di chuyển', () {
      final r = QuickAddParser.parse('grab 25k', categories);
      expect(r.matchedCategoryId, 'cat3');
    });

    test('lương → Lương (income)', () {
      final r = QuickAddParser.parse('lương 10tr', categories);
      expect(r.matchedCategoryId, 'cat5');
      expect(r.type, TransactionType.income);
    });

    test('thưởng → Thưởng (income)', () {
      final r = QuickAddParser.parse('thưởng 1.5tr', categories);
      expect(r.matchedCategoryId, 'cat6');
      expect(r.type, TransactionType.income);
    });

    test('unknown keyword → null', () {
      final r = QuickAddParser.parse('xyz 50k', categories);
      expect(r.matchedCategoryId, isNull);
    });

    test('amount only → no category', () {
      final r = QuickAddParser.parse('50k', categories);
      expect(r.hasAmount, true);
      expect(r.hasCategory, false);
    });
  });

  group('isComplete', () {
    test('amount + category → complete', () {
      final r = QuickAddParser.parse('ăn sáng 50k', categories);
      expect(r.isComplete, true);
    });

    test('amount only → not complete', () {
      final r = QuickAddParser.parse('50k', categories);
      expect(r.isComplete, false);
    });

    test('keyword only → not complete', () {
      final r = QuickAddParser.parse('ăn sáng', categories);
      expect(r.isComplete, false);
    });
  });

  group('Keyword learning', () {
    test('learned keyword takes priority', () {
      QuickAddParser.learn('boba', 'cat2');
      final r = QuickAddParser.parse('boba 40k', categories);
      expect(r.matchedCategoryId, 'cat2');
    });
  });
}
