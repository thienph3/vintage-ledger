import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (amount <= 0) throw Exception('Số tiền phải lớn hơn 0');

    final firestore = FirebaseFirestore.instance;
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();

    await firestore.runTransaction((txn) async {
      // 1. Read goal document
      final goalRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('goals_v2')
          .doc(goalId);
      final goalSnap = await txn.get(goalRef);
      if (!goalSnap.exists) throw Exception('Không tìm thấy mục tiêu');
      final goalData = goalSnap.data()!;
      if (goalData['status'] != 'active') throw Exception('Mục tiêu không ở trạng thái hoạt động');
      final fundingWalletId = goalData['funding_wallet_id'] as String;
      final currentAmount = goalData['current_amount'] as int? ?? 0;
      final targetAmount = goalData['target_amount'] as int? ?? 0;

      // 2. Read wallet balance to compute available balance
      final walletRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('wallets')
          .doc(fundingWalletId);
      final walletSnap = await txn.get(walletRef);
      if (!walletSnap.exists) throw Exception('Không tìm thấy ví');
      final walletBalance = walletSnap.data()!['balance'] as int? ?? 0;

      // 3. Compute earmarked amount for this wallet (sum of all active goals' currentAmount)
      final goalsSnap = await _repo.getActiveGoalsByWallet(fundingWalletId);
      final earmarkedAmount = goalsSnap.fold<int>(0, (total, g) => total + g.currentAmount);
      final availableBalance = walletBalance - earmarkedAmount;

      // 4. Validate amount <= availableBalance
      if (amount > availableBalance) throw Exception('Số tiền vượt quá số dư khả dụng');

      // 5. Create contribution in goal's subcollection
      final contribRef = goalRef.collection('contributions').doc();
      txn.set(contribRef, {
        'goal_id': goalId,
        'amount': amount,
        'date': now.millisecondsSinceEpoch,
        'note': note,
        'created_by': userId,
        'created_at': now.millisecondsSinceEpoch,
      });

      // 6. Update goal current_amount and auto-complete if target reached
      final newCurrentAmount = currentAmount + amount;
      final updates = <String, dynamic>{
        'current_amount': newCurrentAmount,
        'updated_at': now.millisecondsSinceEpoch,
      };
      if (newCurrentAmount >= targetAmount) {
        updates['status'] = 'completed';
      }
      txn.update(goalRef, updates);
    });
  }

  Future<void> rutTuMucTieu(String goalId, int amount, {String? note}) async {
    if (amount <= 0) throw Exception('Số tiền phải lớn hơn 0');

    final firestore = FirebaseFirestore.instance;
    final accountId = sl.appState.currentAccountId;
    final userId = sl.appState.currentUserId ?? '';
    final now = DateTime.now();

    await firestore.runTransaction((txn) async {
      // 1. Read goal document
      final goalRef = firestore
          .collection('accounts')
          .doc(accountId)
          .collection('goals_v2')
          .doc(goalId);
      final goalSnap = await txn.get(goalRef);
      if (!goalSnap.exists) throw Exception('Không tìm thấy mục tiêu');
      final goalData = goalSnap.data()!;
      final currentAmount = goalData['current_amount'] as int? ?? 0;

      // 2. Validate amount <= currentAmount
      if (amount > currentAmount) throw Exception('Số tiền rút vượt quá số tiền đã nạp');

      // 3. Create contribution with negative amount
      final contribRef = goalRef.collection('contributions').doc();
      txn.set(contribRef, {
        'goal_id': goalId,
        'amount': -amount,
        'date': now.millisecondsSinceEpoch,
        'note': note,
        'created_by': userId,
        'created_at': now.millisecondsSinceEpoch,
      });

      // 4. Update goal current_amount
      final newCurrentAmount = currentAmount - amount;
      txn.update(goalRef, {
        'current_amount': newCurrentAmount,
        'updated_at': now.millisecondsSinceEpoch,
      });
    });
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

  /// Tính tổng earmarked amount cho một ví (tổng currentAmount của goals active liên kết)
  Future<int> getEarmarkedAmount(String walletId) async {
    final goals = await _repo.getActiveGoalsByWallet(walletId);
    return goals.fold<int>(0, (total, g) => total + g.currentAmount);
  }

  /// Stream earmarked amount cho một ví (realtime)
  Stream<int> watchEarmarkedAmount(String walletId) {
    return _repo.watchActiveGoalsByWallet(walletId).map(
      (goals) => goals.fold<int>(0, (total, g) => total + g.currentAmount),
    );
  }

  /// Lấy danh sách goal active theo walletId
  Future<List<Goal>> getGoalsByWallet(String walletId) async {
    return await _repo.getActiveGoalsByWallet(walletId);
  }

  /// Stream goal active theo walletId
  Stream<List<Goal>> watchGoalsByWallet(String walletId) {
    return _repo.watchActiveGoalsByWallet(walletId);
  }

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
    await _repo.updateGoal(id, {
      'current_amount': 0,
      'status': GoalStatus.cancelled.name,
    });
  }

  Future<void> deleteGoal(String id) async {
    await _repo.deleteGoal(id);
  }
}
