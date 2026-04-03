import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class ReactionService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference _reactions(String txnId) {
    final accountId = sl.appState.currentAccountId;
    return _firestore
        .collection('accounts').doc(accountId)
        .collection('transactions').doc(txnId)
        .collection('reactions');
  }

  Future<void> addReaction(String txnId, String emoji) async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;
    await _reactions(txnId).doc(userId).set({
      'emoji': emoji,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeReaction(String txnId) async {
    final userId = sl.appState.currentUserId;
    if (userId == null) return;
    await _reactions(txnId).doc(userId).delete();
  }

  Stream<Map<String, String>> watchReactions(String txnId) {
    return _reactions(txnId).snapshots().map((snap) {
      final map = <String, String>{};
      for (final doc in snap.docs) {
        final emoji = (doc.data() as Map<String, dynamic>)['emoji'] as String?;
        if (emoji != null) map[doc.id] = emoji;
      }
      return map;
    });
  }
}
