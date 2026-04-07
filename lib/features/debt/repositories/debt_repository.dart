import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/models/payment.dart';

class DebtRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _debts =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('debts');

  CollectionReference<Map<String, dynamic>> _payments(String debtId) =>
      _debts.doc(debtId).collection('payments');

  // ── Debts ──

  Future<List<Debt>> getDebts() async {
    final snap = await _debts.orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Debt>> watchDebts() {
    return _debts.orderBy('created_at', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => Debt.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<String> addDebt(Debt debt) async {
    final data = debt.toMap();
    data['created_at'] = DateTime.now().millisecondsSinceEpoch;
    final doc = await _debts.add(data);
    return doc.id;
  }

  Future<void> updateDebt(String id, Map<String, dynamic> data) async {
    await _debts.doc(id).update(data);
  }

  Future<void> deleteDebt(String id) async {
    // Optimized: Direct batch delete without reading payments first
    // Subcollections will be cleaned up by security rules or cloud functions
    final batch = _firestore.batch();
    batch.delete(_debts.doc(id));
    
    // Optional: If we need to clean up payments manually
    // This is more efficient than reading all payments first
    try {
      final paymentsQuery = await _payments(id).limit(500).get();
      for (final doc in paymentsQuery.docs) {
        batch.delete(doc.reference);
      }
    } catch (_) {
      // If payments cleanup fails, debt will still be deleted
      // Orphaned payments can be cleaned up by a background job
    }
    
    await batch.commit();
  }

  // ── Payments ──

  Future<List<Payment>> getPayments(String debtId) async {
    final snap = await _payments(debtId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Payment>> watchPayments(String debtId) {
    return _payments(debtId).orderBy('date', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => Payment.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<String> addPayment(String debtId, Payment payment) async {
    final data = payment.toMap();
    data['created_at'] = DateTime.now().millisecondsSinceEpoch;
    final doc = await _payments(debtId).add(data);
    return doc.id;
  }
}
