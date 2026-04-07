import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/transfer/models/transfer.dart';

class TransferRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transfers =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('transfers_v2');

  CollectionReference<Map<String, dynamic>> get _shortcuts =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('transfer_shortcuts');

  // ── Transfers ──

  Future<List<Transfer>> getTransfers() async {
    final snap = await _transfers.orderBy('date', descending: true).limit(100).get();
    return snap.docs.map((d) => Transfer.fromMap(d.id, d.data())).toList();
  }

  Future<List<Transfer>> getTransfersByType(TransferType type) async {
    final snap = await _transfers
        .where('type', isEqualTo: type.name)
        .orderBy('date', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => Transfer.fromMap(d.id, d.data())).toList();
  }

  Future<List<Transfer>> getPendingTransfers() async {
    final snap = await _transfers
        .where('status', isEqualTo: TransferStatus.pending.name)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => Transfer.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Transfer>> watchRecentTransfers() {
    return _transfers
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Transfer.fromMap(d.id, d.data())).toList());
  }

  Future<Transfer?> getTransfer(String id) async {
    final doc = await _transfers.doc(id).get();
    if (!doc.exists) return null;
    return Transfer.fromMap(doc.id, doc.data()!);
  }

  Future<String> addTransfer(Transfer transfer) async {
    final doc = await _transfers.add(transfer.toMap());
    return doc.id;
  }

  Future<void> updateTransfer(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _transfers.doc(id).update(data);
  }

  Future<void> deleteTransfer(String id) async {
    await _transfers.doc(id).delete();
  }

  // ── Shortcuts ──

  Future<List<TransferShortcut>> getShortcuts() async {
    final snap = await _shortcuts.orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => TransferShortcut.fromMap(d.id, d.data())).toList();
  }

  Stream<List<TransferShortcut>> watchShortcuts() {
    return _shortcuts.orderBy('created_at', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => TransferShortcut.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<String> addShortcut(TransferShortcut shortcut) async {
    final doc = await _shortcuts.add(shortcut.toMap());
    return doc.id;
  }

  Future<void> deleteShortcut(String id) async {
    await _shortcuts.doc(id).delete();
  }
}
