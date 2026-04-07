import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/debt_payment.dart';

class DebtRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _debts =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('debts_v2');

  CollectionReference<Map<String, dynamic>> _payments(String debtId) =>
      _debts.doc(debtId).collection('payments');

  // ── Debts ──

  Future<List<Debt>> getDebts() async {
    final snap = await _debts
        .where('created_by', isEqualTo: sl.appState.currentUserId ?? '')
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList();
  }

  Future<List<Debt>> getDebtsByType(DebtType type) async {
    final snap = await _debts
        .where('created_by', isEqualTo: sl.appState.currentUserId ?? '')
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: DebtStatus.active.name)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList();
  }

  Future<List<Debt>> getOverdueDebts() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snap = await _debts
        .where('created_by', isEqualTo: sl.appState.currentUserId ?? '')
        .where('status', isEqualTo: DebtStatus.active.name)
        .where('due_date', isLessThan: now)
        .orderBy('due_date')
        .get();
    return snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Debt>> watchDebts() {
    return _debts
        .where('created_by', isEqualTo: sl.appState.currentUserId ?? '')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Debt>> watchActiveDebts() {
    return _debts
        .where('created_by', isEqualTo: sl.appState.currentUserId ?? '')
        .where('status', isEqualTo: DebtStatus.active.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList());
  }

  Future<Debt?> getDebt(String id) async {
    final doc = await _debts.doc(id).get();
    if (!doc.exists) return null;
    return Debt.fromMap(doc.id, doc.data()!);
  }

  Future<String> addDebt(Debt debt) async {
    final map = debt.toMap();
    map['created_by'] = sl.appState.currentUserId ?? '';
    final doc = await _debts.add(map);
    return doc.id;
  }

  Future<void> updateDebt(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _debts.doc(id).update(data);
  }

  Future<void> deleteDebt(String id) async {
    final batch = _firestore.batch();
    batch.delete(_debts.doc(id));
    
    try {
      final paymentsQuery = await _payments(id).limit(500).get();
      for (final doc in paymentsQuery.docs) {
        batch.delete(doc.reference);
      }
    } catch (_) {}
    
    await batch.commit();
  }

  // ── Payments ──

  Future<List<DebtPayment>> getPayments(String debtId) async {
    final snap = await _payments(debtId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => DebtPayment.fromMap(d.id, d.data())).toList();
  }

  Stream<List<DebtPayment>> watchPayments(String debtId) {
    return _payments(debtId).orderBy('date', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => DebtPayment.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<String> addPayment(String debtId, DebtPayment payment) async {
    final doc = await _payments(debtId).add(payment.toMap());
    return doc.id;
  }

  Future<void> updatePayment(String debtId, String paymentId, Map<String, dynamic> data) async {
    await _payments(debtId).doc(paymentId).update(data);
  }

  Future<void> deletePayment(String debtId, String paymentId) async {
    await _payments(debtId).doc(paymentId).delete();
  }
}
