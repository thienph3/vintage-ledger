import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/wallet/models/wallet_goal.dart';
import 'package:vintage_ledger/features/wallet/repositories/goal_repository.dart';

class GoalService {
  final GoalRepository _repo = GoalRepository();

  Future<List<WalletGoal>> getGoals(String walletId) => _repo.getGoals(walletId);
  Stream<List<WalletGoal>> watchGoals(String walletId) => _repo.watchGoals(walletId);

  Future<String> createGoal(String walletId, WalletGoal goal) async {
    await _validateAllocation(walletId, goal.savedAmount);
    return _repo.addGoal(walletId, goal);
  }

  Future<void> updateSavedAmount(String walletId, String goalId, int savedAmount) async {
    await _validateAllocation(walletId, savedAmount, excludeGoalId: goalId);
    await _repo.updateGoal(walletId, goalId, {'saved_amount': savedAmount});
  }

  Future<void> updateGoal(String walletId, String goalId, Map<String, dynamic> data) async {
    if (data.containsKey('saved_amount')) {
      await _validateAllocation(walletId, data['saved_amount'] as int, excludeGoalId: goalId);
    }
    await _repo.updateGoal(walletId, goalId, data);
  }

  Future<void> deleteGoal(String walletId, String goalId) => _repo.deleteGoal(walletId, goalId);

  Future<void> _validateAllocation(String walletId, int newAmount, {String? excludeGoalId}) async {
    final wallet = await sl.walletService.getWallet(walletId);
    if (wallet == null) throw Exception('Wallet not found');
    final goals = await _repo.getGoals(walletId);
    final otherTotal = goals
        .where((g) => g.id != excludeGoalId)
        .fold<int>(0, (s, g) => s + g.savedAmount);
    if (otherTotal + newAmount > wallet.balance) {
      throw Exception('Total allocation exceeds wallet balance');
    }
  }
}
