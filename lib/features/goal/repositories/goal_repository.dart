import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/models/goal_contribution.dart';
import 'package:vintage_ledger/features/goal/models/auto_saving_rule.dart';

class GoalRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _goals =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('goals_v2');

  CollectionReference<Map<String, dynamic>> _contributions(String goalId) =>
      _goals.doc(goalId).collection('contributions');

  CollectionReference<Map<String, dynamic>> get _autoSavingRules =>
      _firestore.collection('accounts').doc(sl.appState.currentAccountId).collection('auto_saving_rules');

  // ── Goals ──

  Future<List<Goal>> getGoals() async {
    final snap = await _goals
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList();
  }

  Future<List<Goal>> getActiveGoals() async {
    final snap = await _goals
        .where('status', isEqualTo: GoalStatus.active.name)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList();
  }

  Future<List<Goal>> getGoalsByCategory(GoalCategory category) async {
    final snap = await _goals
        .where('category', isEqualTo: category.name)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList();
  }

  Future<List<Goal>> getCompletedGoals() async {
    final snap = await _goals
        .where('status', isEqualTo: GoalStatus.completed.name)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Goal>> watchGoals() {
    return _goals
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Goal>> watchActiveGoals() {
    return _goals
        .where('status', isEqualTo: GoalStatus.active.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList());
  }

  Future<List<Goal>> getActiveGoalsByWallet(String walletId) async {
    final snap = await _goals
        .where('funding_wallet_id', isEqualTo: walletId)
        .where('status', isEqualTo: GoalStatus.active.name)
        .get();
    return snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Goal>> watchActiveGoalsByWallet(String walletId) {
    return _goals
        .where('funding_wallet_id', isEqualTo: walletId)
        .where('status', isEqualTo: GoalStatus.active.name)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList());
  }

  Future<Goal?> getGoal(String id) async {
    final doc = await _goals.doc(id).get();
    if (!doc.exists) return null;
    return Goal.fromMap(doc.id, doc.data()!);
  }

  Future<String> addGoal(Goal goal) async {
    final map = goal.toMap();
    map['created_by'] = sl.appState.currentUserId ?? '';
    final doc = await _goals.add(map);
    return doc.id;
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _goals.doc(id).update(data);
  }

  Future<void> deleteGoal(String id) async {
    final batch = _firestore.batch();
    batch.delete(_goals.doc(id));
    
    try {
      final contributionsQuery = await _contributions(id).limit(500).get();
      for (final doc in contributionsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      final rulesQuery = await _autoSavingRules.where('goal_id', isEqualTo: id).get();
      for (final doc in rulesQuery.docs) {
        batch.delete(doc.reference);
      }
    } catch (_) {}
    
    await batch.commit();
  }

  // ── Contributions ──

  Future<List<GoalContribution>> getContributions(String goalId) async {
    final snap = await _contributions(goalId).orderBy('date', descending: true).get();
    return snap.docs.map((d) => GoalContribution.fromMap(d.id, d.data())).toList();
  }

  Stream<List<GoalContribution>> watchContributions(String goalId) {
    return _contributions(goalId).orderBy('date', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => GoalContribution.fromMap(d.id, d.data())).toList(),
    );
  }

  Future<String> addContribution(String goalId, GoalContribution contribution) async {
    final doc = await _contributions(goalId).add(contribution.toMap());
    return doc.id;
  }

  // ── Auto Saving Rules ──

  Future<List<AutoSavingRule>> getAutoSavingRules() async {
    final snap = await _autoSavingRules
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs.map((d) => AutoSavingRule.fromMap(d.id, d.data())).toList();
  }

  Future<List<AutoSavingRule>> getActiveAutoSavingRules() async {
    final snap = await _autoSavingRules
        .where('is_active', isEqualTo: true)
        .orderBy('next_run_date')
        .get();
    return snap.docs.map((d) => AutoSavingRule.fromMap(d.id, d.data())).toList();
  }

  Future<AutoSavingRule?> getAutoSavingRuleByGoal(String goalId) async {
    final snap = await _autoSavingRules.where('goal_id', isEqualTo: goalId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return AutoSavingRule.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  Stream<AutoSavingRule?> watchAutoSavingRuleByGoal(String goalId) {
    return _autoSavingRules
        .where('goal_id', isEqualTo: goalId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return AutoSavingRule.fromMap(snap.docs.first.id, snap.docs.first.data());
    });
  }

  Future<String> addAutoSavingRule(AutoSavingRule rule) async {
    final map = rule.toMap();
    map['created_by'] = sl.appState.currentUserId ?? '';
    final doc = await _autoSavingRules.add(map);
    return doc.id;
  }

  Future<void> updateAutoSavingRule(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    await _autoSavingRules.doc(id).update(data);
  }

  Future<void> deleteAutoSavingRule(String id) async {
    await _autoSavingRules.doc(id).delete();
  }
}
