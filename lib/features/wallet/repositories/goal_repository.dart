import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/wallet/models/wallet_goal.dart';

class GoalRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goals(String walletId) =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId)
          .collection('wallets').doc(walletId).collection('goals');

  Future<List<WalletGoal>> getGoals(String walletId) async {
    final snap = await _goals(walletId).orderBy('created_at').get();
    return snap.docs.map((d) => WalletGoal.fromMap(d.id, d.data())).toList();
  }

  Stream<List<WalletGoal>> watchGoals(String walletId) {
    return _goals(walletId).orderBy('created_at').snapshots().map(
      (snap) => snap.docs.map((d) => WalletGoal.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<String> addGoal(String walletId, WalletGoal goal) async {
    final data = goal.toMap();
    data['created_at'] = DateTime.now().millisecondsSinceEpoch;
    final doc = await _goals(walletId).add(data);
    return doc.id;
  }

  Future<void> updateGoal(String walletId, String goalId, Map<String, dynamic> data) async {
    await _goals(walletId).doc(goalId).update(data);
  }

  Future<void> deleteGoal(String walletId, String goalId) async {
    await _goals(walletId).doc(goalId).delete();
  }
}
