import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/wallet/models/wallet_goal.dart';
import 'package:vintage_ledger/features/wallet/repositories/goal_repository.dart';

class GoalService {
  final GoalRepository _repo = GoalRepository();

  Future<List<WalletGoal>> getGoals(String walletId) => _repo.getGoals(walletId);
  Stream<List<WalletGoal>> watchGoals(String walletId) => _repo.watchGoals(walletId);

  Future<String> createGoal(String walletId, WalletGoal goal) async {
    return _repo.addGoal(walletId, goal);
  }

  Future<void> updateGoal(String walletId, String goalId, Map<String, dynamic> data) async {
    await _repo.updateGoal(walletId, goalId, data);
  }

  Future<void> deleteGoal(String walletId, String goalId) => _repo.deleteGoal(walletId, goalId);

  /// Assign a transaction to a goal: set txn.goalId + increment goal.savedAmount
  Future<void> assignGoal({
    required String walletId,
    required String transactionId,
    required String goalId,
    required int amount,
  }) async {
    // Update transaction
    await sl.transactionService.updateTransactionField(transactionId, {'goal_id': goalId});
    // Increment goal savedAmount
    final goals = await _repo.getGoals(walletId);
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal != null) {
      await _repo.updateGoal(walletId, goalId, {'saved_amount': goal.savedAmount + amount});
    }
  }

  /// Unassign a transaction from a goal: clear txn.goalId + decrement goal.savedAmount
  Future<void> unassignGoal({
    required String walletId,
    required String transactionId,
    required String goalId,
    required int amount,
  }) async {
    await sl.transactionService.updateTransactionField(transactionId, {'goal_id': null});
    final goals = await _repo.getGoals(walletId);
    final goal = goals.where((g) => g.id == goalId).firstOrNull;
    if (goal != null) {
      await _repo.updateGoal(walletId, goalId, {
        'saved_amount': (goal.savedAmount - amount).clamp(0, goal.targetAmount),
      });
    }
  }
}
