import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/debt_payment.dart';
import 'package:vintage_ledger/features/debt/repositories/debt_repository.dart';

class DebtService {
  final _repo = DebtRepository();

  // ── Core Operations ──

  Future<String> choVay({
    required String partyName,
    required int amount,
    String? contact,
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final now = DateTime.now();
    final debt = Debt(
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
      walletId: walletId,
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
    String? walletId,
    DateTime? dueDate,
    double? interestRate,
    String? description,
  }) async {
    final now = DateTime.now();
    final debt = Debt(
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
      walletId: walletId,
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addDebt(debt);
  }

  Future<void> nhanTienTra(String debtId, int amount, {
    required String walletId,
    String? note,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();

    // Resolve system category
    final sysCat = await sl.categoryService.ensureSystemCategory('debt_payment');
    final categoryId = sysCat.id ?? '';

    await firestore.runTransaction((txn) async {
      // 1. Read debt document
      final debtRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(debtId);
      final debtSnap = await txn.get(debtRef);
      if (!debtSnap.exists) throw Exception('Debt not found');
      final debtData = debtSnap.data()!;
      if (debtData['type'] != 'lend') throw Exception('Not a lend debt');
      final paidAmount = debtData['paid_amount'] as int? ?? 0;
      final totalAmount = debtData['total_amount'] as int? ?? 0;

      // 2. Read wallet balance
      final walletRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('wallets')
          .doc(walletId);
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception('Wallet not found');
      final walletBalance = walletSnap.data()!['balance'] as int? ?? 0;

      // 3. Create income transaction
      final txnRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('transactions')
          .doc();
      txn.set(txnRef, {
        'wallet_id': walletId,
        'category_id': categoryId,
        'type': 'income',
        'amount': amount,
        'note': note ?? 'Nhận trả nợ',
        'date': now.millisecondsSinceEpoch,
        'created_by': userId,
        'debt_id': debtId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. Add to wallet balance
      txn.update(walletRef, {'balance': walletBalance + amount});

      // 5. Create payment in debt's subcollection
      final paymentRef = debtRef.collection('payments').doc();
      txn.set(paymentRef, {
        'debt_id': debtId,
        'amount': amount,
        'date': now.millisecondsSinceEpoch,
        'note': note,
        'created_by': userId,
        'created_at': now.millisecondsSinceEpoch,
      });

      // 6. Update debt paid_amount and status if completed
      final newPaidAmount = paidAmount + amount;
      final updates = <String, dynamic>{
        'paid_amount': newPaidAmount,
        'updated_at': now.millisecondsSinceEpoch,
      };
      if (newPaidAmount >= totalAmount) {
        updates['status'] = 'completed';
      }
      txn.update(debtRef, updates);
    });
  }

  Future<void> traNop(String debtId, int amount, {
    required String walletId,
    String? note,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();

    // Resolve system category
    final sysCat = await sl.categoryService.ensureSystemCategory('debt_payment');
    final categoryId = sysCat.id ?? '';

    await firestore.runTransaction((txn) async {
      // 1. Read debt document
      final debtRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('debts_v2')
          .doc(debtId);
      final debtSnap = await txn.get(debtRef);
      if (!debtSnap.exists) throw Exception('Debt not found');
      final debtData = debtSnap.data()!;
      if (debtData['type'] != 'borrow') throw Exception('Not a borrow debt');
      final paidAmount = debtData['paid_amount'] as int? ?? 0;
      final totalAmount = debtData['total_amount'] as int? ?? 0;

      // 2. Read wallet balance
      final walletRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('wallets')
          .doc(walletId);
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception('Wallet not found');
      final walletBalance = walletSnap.data()!['balance'] as int? ?? 0;

      // 3. Create expense transaction
      final txnRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('transactions')
          .doc();
      txn.set(txnRef, {
        'wallet_id': walletId,
        'category_id': categoryId,
        'type': 'expense',
        'amount': amount,
        'note': note ?? 'Trả nợ',
        'date': now.millisecondsSinceEpoch,
        'created_by': userId,
        'debt_id': debtId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 4. Deduct wallet balance
      txn.update(walletRef, {'balance': walletBalance - amount});

      // 5. Create payment in debt's subcollection
      final paymentRef = debtRef.collection('payments').doc();
      txn.set(paymentRef, {
        'debt_id': debtId,
        'amount': amount,
        'date': now.millisecondsSinceEpoch,
        'note': note,
        'created_by': userId,
        'created_at': now.millisecondsSinceEpoch,
      });

      // 6. Update debt paid_amount and status if completed
      final newPaidAmount = paidAmount + amount;
      final updates = <String, dynamic>{
        'paid_amount': newPaidAmount,
        'updated_at': now.millisecondsSinceEpoch,
      };
      if (newPaidAmount >= totalAmount) {
        updates['status'] = 'completed';
      }
      txn.update(debtRef, updates);
    });
  }

  // ── Queries ──

  Future<List<Debt>> getTienChoVay() async {
    return await _repo.getDebtsByType(DebtType.lend);
  }

  Future<List<Debt>> getTienVayMuon() async {
    return await _repo.getDebtsByType(DebtType.borrow);
  }

  Future<List<Debt>> getOverdueDebts() async {
    return await _repo.getOverdueDebts();
  }

  Stream<List<Debt>> watchActiveDebts() {
    return _repo.watchActiveDebts();
  }

  Stream<List<Debt>> watchDebtsByWallet(String walletId) {
    return _repo.watchActiveDebtsByWallet(walletId);
  }

  Future<List<Debt>> getDebtsByWallet(String walletId) async {
    return await _repo.getActiveDebtsByWallet(walletId);
  }

  Future<Debt?> getDebt(String id) async {
    return await _repo.getDebt(id);
  }

  Future<List<DebtPayment>> getPayments(String debtId) async {
    return await _repo.getPayments(debtId);
  }

  Stream<List<DebtPayment>> watchPayments(String debtId) {
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
