import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/models/goal_contribution.dart';
import 'package:vintage_ledger/features/goal/models/auto_saving_rule.dart';
import 'package:vintage_ledger/features/goal/repositories/goal_repository.dart';

class GoalService {
  final _repo = GoalRepository();

  // ── Core Operations ──

  Future<String> taoMucTieu({
    required String name,
    required GoalCategory category,
    required int targetAmount,
    required String fundingWalletId,
    DateTime? targetDate,
  }) async {
    final now = DateTime.now();
    final goal = Goal(
      id: '',
      accountId: sl.appState.currentAccountId,
      name: name,
      category: category,
      targetAmount: targetAmount,
      currentAmount: 0,
      targetDate: targetDate,
      fundingWalletId: fundingWalletId,
      status: GoalStatus.active,
      createdAt: now,
      updatedAt: now,
    );
    return await _repo.addGoal(goal);
  }

  Future<void> napVaoMucTieu(String goalId, int amount, {String? note}) async {
    final goal = await _repo.getGoal(goalId);
    if (goal == null || !goal.isActive) return;

    final now = DateTime.now();
    final contribution = GoalContribution(
      id: '',
      goalId: goalId,
      amount: amount,
      date: now,
      note: note,
      createdBy: sl.appState.currentUserId ?? '',
      createdAt: now,
    );

    await _repo.addContribution(goalId, contribution);

    final newCurrentAmount = goal.currentAmount + amount;
    final updates = <String, dynamic>{
      'current_amount': newCurrentAmount,
    };

    if (newCurrentAmount >= goal.targetAmount) {
      updates['status'] = GoalStatus.completed.name;
    }

    await _repo.updateGoal(goalId, updates);
  }

  Future<void> rutTuMucTieu(String goalId, int amount, {String? note}) async {
    final goal = await _repo.getGoal(goalId);
    if (goal == null) return;

    final now = DateTime.now();
    final contribution = GoalContribution(
      id: '',
      goalId: goalId,
      amount: -amount,
      date: now,
      note: note,
      createdBy: sl.appState.currentUserId ?? '',
      createdAt: now,
    );

    await _repo.addContribution(goalId, contribution);

    final newCurrentAmount = (goal.currentAmount - amount).clamp(0, goal.targetAmount);
    await _repo.updateGoal(goalId, {'current_amount': newCurrentAmount});
  }

  // ── Auto-Saving ──

  Future<void> thietLapTietKiemTuDong({
    required String goalId,
    required int amount,
    required RecurrenceType frequency,
  }) async {
    final existing = await _repo.getAutoSavingRuleByGoal(goalId);
    if (existing != null) {
      await _repo.deleteAutoSavingRule(existing.id);
    }

    final now = DateTime.now();
    final rule = AutoSavingRule(
      id: '',
      goalId: goalId,
      amount: amount,
      frequency: frequency,
      nextRunDate: _calculateNextRunDate(frequency),
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _repo.addAutoSavingRule(rule);
  }

  Future<void> pauseAutoSaving(String goalId) async {
    final rule = await _repo.getAutoSavingRuleByGoal(goalId);
    if (rule != null) {
      await _repo.updateAutoSavingRule(rule.id, {'is_active': false});
    }
  }

  Future<void> resumeAutoSaving(String goalId) async {
    final rule = await _repo.getAutoSavingRuleByGoal(goalId);
    if (rule != null) {
      await _repo.updateAutoSavingRule(rule.id, {
        'is_active': true,
        'next_run_date': _calculateNextRunDate(rule.frequency).millisecondsSinceEpoch,
      });
    }
  }

  DateTime _calculateNextRunDate(RecurrenceType frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case RecurrenceType.daily:
        return DateTime(now.year, now.month, now.day + 1);
      case RecurrenceType.weekly:
        return DateTime(now.year, now.month, now.day + 7);
      case RecurrenceType.monthly:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }

  // ── Queries ──

  Future<List<Goal>> getActiveGoals() async {
    return await _repo.getActiveGoals();
  }

  Future<List<Goal>> getGoalsByCategory(GoalCategory category) async {
    return await _repo.getGoalsByCategory(category);
  }

  Future<List<Goal>> getCompletedGoals() async {
    return await _repo.getCompletedGoals();
  }

  Stream<List<Goal>> watchGoalsProgress() {
    return _repo.watchActiveGoals();
  }

  Future<Goal?> getGoal(String id) async {
    return await _repo.getGoal(id);
  }

  Future<List<GoalContribution>> getContributions(String goalId) async {
    return await _repo.getContributions(goalId);
  }

  Stream<List<GoalContribution>> watchContributions(String goalId) {
    return _repo.watchContributions(goalId);
  }

  Future<AutoSavingRule?> getAutoSavingRule(String goalId) async {
    return await _repo.getAutoSavingRuleByGoal(goalId);
  }

  Stream<AutoSavingRule?> watchAutoSavingRule(String goalId) {
    return _repo.watchAutoSavingRuleByGoal(goalId);
  }

  // ── Management ──

  Future<void> updateGoal(String id, {
    String? name,
    int? targetAmount,
    DateTime? targetDate,
    String? fundingWalletId,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (targetAmount != null) updates['target_amount'] = targetAmount;
    if (targetDate != null) updates['target_date'] = targetDate.millisecondsSinceEpoch;
    if (fundingWalletId != null) updates['funding_wallet_id'] = fundingWalletId;

    if (updates.isNotEmpty) {
      await _repo.updateGoal(id, updates);
    }
  }

  Future<void> pauseGoal(String id) async {
    await _repo.updateGoal(id, {'status': GoalStatus.paused.name});
  }

  Future<void> resumeGoal(String id) async {
    await _repo.updateGoal(id, {'status': GoalStatus.active.name});
  }

  Future<void> cancelGoal(String id) async {
    await _repo.updateGoal(id, {'status': GoalStatus.cancelled.name});
  }

  Future<void> deleteGoal(String id) async {
    await _repo.deleteGoal(id);
  }
}
