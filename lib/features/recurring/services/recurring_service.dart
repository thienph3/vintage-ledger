import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/recurring/models/recurring_rule.dart';
import 'package:vintage_ledger/features/recurring/repositories/recurring_rule_repository.dart';

class RecurringService {
  final _repo = RecurringRuleRepository();

  RecurringRuleRepository get repo => _repo;

  Future<String> createRule(RecurringRule rule) => _repo.add(rule);

  Future<void> updateRule(String id, Map<String, dynamic> data) => _repo.update(id, data);

  Future<void> deleteRule(String id) => _repo.delete(id);

  Future<List<RecurringRule>> getRules() => _repo.getAll();

  Stream<List<RecurringRule>> watchRules() => _repo.watchAll();

  Future<void> checkAndRun() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final dueRules = await _repo.getDueRules(now);
      for (final rule in dueRules) {
        await _executeRule(rule);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Recurring] checkAndRun error: $e');
    }
  }

  Future<void> _executeRule(RecurringRule rule) async {
    final firestore = _repo.firestore;
    final ruleRef = _repo.collection.doc(rule.id);

    await firestore.runTransaction((txn) async {
      final snap = await txn.get(ruleRef);
      if (!snap.exists) return;
      final current = RecurringRule.fromMap(snap.id, snap.data()!);
      if (!current.enabled || current.nextRunAt > DateTime.now().millisecondsSinceEpoch) return;

      // Create transaction
      final txnRef = sl.walletService.repo.firestore
          .collection('accounts').doc(sl.appState.currentAccountId)
          .collection('transactions').doc();

      txn.set(txnRef, {
        'wallet_id': current.walletId,
        'category_id': current.categoryId,
        'type': current.type.value,
        'amount': current.amount,
        'note': current.note,
        'date': DateTime.now().millisecondsSinceEpoch,
        'created_by': sl.appState.currentUserId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update wallet balance
      final walletRef = sl.walletService.repo.collection.doc(current.walletId);
      final walletSnap = await txn.get(walletRef);
      if (walletSnap.exists) {
        final oldBalance = walletSnap.data()?['balance'] ?? 0;
        final delta = current.type.isIncome ? current.amount : -current.amount;
        txn.update(walletRef, {'balance': oldBalance + delta});
      }

      // Update next_run_at
      txn.update(ruleRef, {
        'next_run_at': calcNextRun(current.frequency, current.nextRunAt),
      });
    });
  }

  static int calcNextRun(Frequency frequency, int currentMs) {
    final current = DateTime.fromMillisecondsSinceEpoch(currentMs);
    final next = switch (frequency) {
      Frequency.daily => current.add(const Duration(days: 1)),
      Frequency.weekly => current.add(const Duration(days: 7)),
      Frequency.monthly => DateTime(current.year, current.month + 1, current.day),
    };
    return next.millisecondsSinceEpoch;
  }
}
