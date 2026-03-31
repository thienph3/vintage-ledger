import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

void main() {
  group('TransactionType', () {
    test('value returns name string', () {
      expect(TransactionType.income.value, 'income');
      expect(TransactionType.expense.value, 'expense');
    });

    test('fromString parses valid values', () {
      expect(TransactionType.fromString('income'), TransactionType.income);
      expect(TransactionType.fromString('expense'), TransactionType.expense);
    });

    test('fromString defaults to expense for invalid input', () {
      expect(TransactionType.fromString('invalid'), TransactionType.expense);
      expect(TransactionType.fromString(''), TransactionType.expense);
    });

    test('isIncome and isExpense helpers', () {
      expect(TransactionType.income.isIncome, true);
      expect(TransactionType.income.isExpense, false);
      expect(TransactionType.expense.isIncome, false);
      expect(TransactionType.expense.isExpense, true);
    });
  });
}
