import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/debt/models/debt_v2.dart';
import 'package:vintage_ledger/features/debt/models/debt_payment_v2.dart';
import 'package:vintage_ledger/features/debt/repositories/debt_repository_v2.dart';

class DebtServiceV2 {
  final _repo = DebtRepositoryV2();

  // ── Core Operations ──

  Future<String> choVay({
    required String partyName,
    required int amount,
    String? contact,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final now = DateTime.now();
    final debt = DebtV2(
      id: '',
      accountId: sl.appState.currentAccountId,
      type: DebtType.lend,
      partyName: partyName,
      partyContact: contact,
      totalAmount: amount,
      paidAmount: 0,
      dueDate: dueDate,
      interestRate: interestRate,
      description: description,
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addDebt(debt);
  }

  Future<String> vayMuon({
    required String partyName,
    required int amount,
    String? contact,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final now = DateTime.now();
    final debt = DebtV2(
      id: '',
      accountId: sl.appState.currentAccountId,
      type: DebtType.borrow,
      partyName: partyName,
      partyContact: contact,
      totalAmount: amount,
      paidAmount: 0,
      dueDate: dueDate,
      interestRate: interestRate,
      description: description,
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addDebt(debt);
  }

  Future<void> nhanTienTra(String debtId, int amount, {String? note}) async {
    final debt = await _repo.getDebt(debtId);
    if (debt == null || debt.type != DebtType.lend) return;

    final now = DateTime.now();
    final payment = DebtPaymentV2(
      id: '',
      debtId: debtId,
      amount: amount,
      date: now,
      note: note,
      createdBy: sl.appState.currentUserId,
      createdAt: now,
    );

    await _repo.addPayment(debtId, payment);

    final newPaidAmount = debt.paidAmount + amount;
    final updates = <String, dynamic>{
      'paid_amount': newPaidAmount,
    };

    if (newPaidAmount >= debt.totalAmount) {
      updates['status'] = DebtStatus.completed.name;
    }

    await _repo.updateDebt(debtId, updates);
  }

  Future<void> traNop(String debtId, int amount, {String? note}) async {
    final debt = await _repo.getDebt(debtId);
    if (debt == null || debt.type != DebtType.borrow) return;

    final now = DateTime.now();
    final payment = DebtPaymentV2(
      id: '',
      debtId: debtId,
      amount: amount,
      date: now,
      note: note,
      createdBy: sl.appState.currentUserId,
      createdAt: now,
    );

    await _repo.addPayment(debtId, payment);

    final newPaidAmount = debt.paidAmount + amount;
    final updates = <String, dynamic>{
      'paid_amount': newPaidAmount,
    };

    if (newPaidAmount >= debt.totalAmount) {
      updates['status'] = DebtStatus.completed.name;
    }

    await _repo.updateDebt(debtId, updates);
  }

  // ── Queries ──

  Future<List<DebtV2>> getTienChoVay() async {
    return await _repo.getDebtsByType(DebtType.lend);
  }

  Future<List<DebtV2>> getTienVayMuon() async {
    return await _repo.getDebtsByType(DebtType.borrow);
  }

  Future<List<DebtV2>> getOverdueDebts() async {
    return await _repo.getOverdueDebts();
  }

  Stream<List<DebtV2>> watchActiveDebts() {
    return _repo.watchActiveDebts();
  }

  Future<DebtV2?> getDebt(String id) async {
    return await _repo.getDebt(id);
  }

  Future<List<DebtPaymentV2>> getPayments(String debtId) async {
    return await _repo.getPayments(debtId);
  }

  Stream<List<DebtPaymentV2>> watchPayments(String debtId) {
    return _repo.watchPayments(debtId);
  }

  // ── Management ──

  Future<void> updateDebt(String id, {
    String? partyName,
    String? partyContact,
    int? totalAmount,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (partyName != null) updates['party_name'] = partyName;
    if (partyContact != null) updates['party_contact'] = partyContact;
    if (totalAmount != null) updates['total_amount'] = totalAmount;
    if (dueDate != null) updates['due_date'] = dueDate.millisecondsSinceEpoch;
    if (interestRate != null) updates['interest_rate'] = interestRate;
    if (description != null) updates['description'] = description;

    if (updates.isNotEmpty) {
      await _repo.updateDebt(id, updates);
    }
  }

  Future<void> cancelDebt(String id) async {
    await _repo.updateDebt(id, {'status': DebtStatus.cancelled.name});
  }

  Future<void> deleteDebt(String id) async {
    await _repo.deleteDebt(id);
  }
}
