import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/transfer/models/transfer.dart';

class TransferRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shortcuts =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('transfer_shortcuts');

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
