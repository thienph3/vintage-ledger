import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/payment.dart';
import 'package:vintage_ledger/features/debt/repositories/debt_repository.dart';

class DebtService {
  final DebtRepository _repo = DebtRepository();

  Future<List<Debt>> getDebts() => _repo.getDebts();
  Stream<List<Debt>> watchDebts() => _repo.watchDebts();
  Future<List<Payment>> getPayments(String debtId) => _repo.getPayments(debtId);
  Stream<List<Payment>> watchPayments(String debtId) => _repo.watchPayments(debtId);

  Future<String> createDebt(Debt debt, {bool createTransaction = false}) async {
    final id = await _repo.addDebt(debt);

    if (createTransaction && debt.walletId != null) {
      final type = debt.isLend ? TransactionType.expense : TransactionType.income;
      final note = debt.isLend ? 'Cho ${debt.partyName} mượn' : 'Vay ${debt.partyName}';
      await sl.transactionService.createTransaction(
        walletId: debt.walletId!,
        categoryId: '',
        type: type,
        amount: debt.totalAmount,
        note: note,
        date: DateTime.now().millisecondsSinceEpoch,
      );
    }

    return id;
  }

  Future<void> recordPayment(String debtId, Payment payment, {bool createTransaction = false, String? walletId}) async {
    final debt = (await _repo.getDebts()).where((d) => d.id == debtId).firstOrNull;
    if (debt == null) throw Exception('Debt not found');

    String? txnId;
    if (createTransaction && walletId != null) {
      final type = debt.isLend ? TransactionType.income : TransactionType.expense;
      final note = debt.isLend ? '${debt.partyName} trả nợ' : 'Trả nợ ${debt.partyName}';
      txnId = await sl.transactionService.createTransaction(
        walletId: walletId,
        categoryId: '',
        type: type,
        amount: payment.amount,
        note: note,
        date: payment.date,
      );
    }

    await _repo.addPayment(debtId, Payment(
      amount: payment.amount,
      date: payment.date,
      note: payment.note,
      transactionId: txnId,
    ));

    final newPaid = debt.paidAmount + payment.amount;
    final settled = newPaid >= debt.totalAmount;
    await _repo.updateDebt(debtId, {
      'paid_amount': newPaid,
      if (settled) 'settled': true,
    });
  }

  Future<void> deleteDebt(String id) => _repo.deleteDebt(id);
}
