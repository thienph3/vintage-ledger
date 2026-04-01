import 'package:flutter_test/flutter_test.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';

/// Pure balance calculation logic extracted from TransactionService.runTransaction
/// Tests verify the math is correct for all edge cases.
int calcBalanceAfterCreate(int currentBalance, TransactionType type, int amount) {
  return currentBalance + (type.isIncome ? amount : -amount);
}

int calcBalanceAfterDelete(int currentBalance, TransactionType type, int amount) {
  return currentBalance + (type.isIncome ? -amount : amount);
}

/// Returns (newBalance, oldWalletDelta, newWalletDelta) for update
({int sameWalletBalance, int oldWalletDelta, int newWalletDelta}) calcBalanceAfterUpdate({
  required int currentBalance,
  required TransactionType oldType,
  required int oldAmount,
  required TransactionType newType,
  required int newAmount,
  required bool sameWallet,
}) {
  if (sameWallet) {
    var balance = currentBalance;
    balance += oldType.isIncome ? -oldAmount : oldAmount; // revert
    balance += newType.isIncome ? newAmount : -newAmount;  // apply
    return (sameWalletBalance: balance, oldWalletDelta: 0, newWalletDelta: 0);
  }
  final oldDelta = oldType.isIncome ? -oldAmount : oldAmount;
  final newDelta = newType.isIncome ? newAmount : -newAmount;
  return (sameWalletBalance: 0, oldWalletDelta: oldDelta, newWalletDelta: newDelta);
}

void main() {
  group('Create transaction balance', () {
    test('expense reduces balance', () {
      expect(calcBalanceAfterCreate(1000000, TransactionType.expense, 100000), 900000);
    });

    test('income increases balance', () {
      expect(calcBalanceAfterCreate(1000000, TransactionType.income, 500000), 1500000);
    });

    test('expense can make balance negative', () {
      expect(calcBalanceAfterCreate(50000, TransactionType.expense, 100000), -50000);
    });
  });

  group('Delete transaction balance', () {
    test('delete expense reverts (increases) balance', () {
      expect(calcBalanceAfterDelete(900000, TransactionType.expense, 100000), 1000000);
    });

    test('delete income reverts (decreases) balance', () {
      expect(calcBalanceAfterDelete(1500000, TransactionType.income, 500000), 1000000);
    });
  });

  group('Update transaction — same wallet', () {
    test('#1: change amount (100k → 200k expense)', () {
      final r = calcBalanceAfterUpdate(
        currentBalance: 900000, // after original 100k expense from 1M
        oldType: TransactionType.expense, oldAmount: 100000,
        newType: TransactionType.expense, newAmount: 200000,
        sameWallet: true,
      );
      // revert +100k → 1M, apply -200k → 800k
      expect(r.sameWalletBalance, 800000);
    });

    test('#2: change type (expense 100k → income 100k)', () {
      final r = calcBalanceAfterUpdate(
        currentBalance: 900000,
        oldType: TransactionType.expense, oldAmount: 100000,
        newType: TransactionType.income, newAmount: 100000,
        sameWallet: true,
      );
      // revert +100k → 1M, apply +100k → 1.1M
      expect(r.sameWalletBalance, 1100000);
    });

    test('#4: change amount + type (expense 100k → income 200k)', () {
      final r = calcBalanceAfterUpdate(
        currentBalance: 900000,
        oldType: TransactionType.expense, oldAmount: 100000,
        newType: TransactionType.income, newAmount: 200000,
        sameWallet: true,
      );
      // revert +100k → 1M, apply +200k → 1.2M
      expect(r.sameWalletBalance, 1200000);
    });
  });

  group('Update transaction — different wallet', () {
    test('#3: move expense 100k from A to B', () {
      final r = calcBalanceAfterUpdate(
        currentBalance: 0, // not used for different wallet
        oldType: TransactionType.expense, oldAmount: 100000,
        newType: TransactionType.expense, newAmount: 100000,
        sameWallet: false,
      );
      // A: revert expense → +100k
      expect(r.oldWalletDelta, 100000);
      // B: apply expense → -100k
      expect(r.newWalletDelta, -100000);
    });

    test('#4: A expense 100k → B income 200k', () {
      final r = calcBalanceAfterUpdate(
        currentBalance: 0,
        oldType: TransactionType.expense, oldAmount: 100000,
        newType: TransactionType.income, newAmount: 200000,
        sameWallet: false,
      );
      // A: revert expense → +100k
      expect(r.oldWalletDelta, 100000);
      // B: apply income → +200k
      expect(r.newWalletDelta, 200000);
    });
  });
}
