import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/coaching/coaching_tip.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';

class CoachingService {
  static Set<String> _dismissed = {};
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await sl.settingService.getSetting('dismissed_tips');
      if (raw != null && raw.isNotEmpty) {
        _dismissed = raw.split(',').toSet();
      }
    } catch (_) {}
    _loaded = true;
  }

  static Future<void> dismiss(String key) async {
    _dismissed.add(key);
    try {
      await sl.settingService.setSetting('dismissed_tips', _dismissed.join(','));
    } catch (_) {}
  }

  /// Returns highest-priority tip, or null if none applicable / all dismissed.
  static Future<CoachingTip?> getTip({
    required BuildContext context,
    required DashboardData? dashboard,
    required int streak,
    required int budgetCount,
    VoidCallback? onNavigateBudget,
  }) async {
    await _ensureLoaded();

    // Priority 1: No transactions
    if (dashboard == null || dashboard.monthly.isEmpty) {
      return _tipIfNotDismissed(
        key: 'no_txn',
        message: S.of(context, 'emptyTransactionHint'),
        icon: Icons.edit_note,
      );
    }

    // Priority 2: Has txn, no budget
    if (dashboard.monthly.length > 5 && budgetCount == 0) {
      final topCat = _topCategory(dashboard);
      if (topCat != null) {
        return _tipIfNotDismissed(
          key: 'no_budget',
          message: S.of(context, 'coachBudgetSuggestion').replaceAll('{category}', topCat),
          icon: Icons.savings_outlined,
          actionLabel: S.of(context, 'setBudget'),
          action: onNavigateBudget,
        );
      }
    }

    // Priority 3: After 3+ days — top category
    if (streak >= 3) {
      final topCat = _topCategory(dashboard);
      if (topCat != null) {
        return _tipIfNotDismissed(
          key: 'top_cat_$topCat',
          message: S.of(context, 'coachTopCategory').replaceAll('{category}', topCat),
          icon: Icons.local_cafe,
        );
      }
    }

    // Priority 4: After 7+ days — weekly comparison
    if (streak >= 7 && dashboard.monthExpense > 0) {
      // Simplified: compare first half vs second half of monthly data
      final now = DateTime.now();
      final midMonth = DateTime(now.year, now.month, 15);
      final firstHalf = dashboard.monthly
          .where((t) => DateTime.fromMillisecondsSinceEpoch(t.transaction.date).isBefore(midMonth))
          .fold<int>(0, (s, t) => s + t.transaction.amount);
      final secondHalf = dashboard.monthly
          .where((t) => !DateTime.fromMillisecondsSinceEpoch(t.transaction.date).isBefore(midMonth))
          .fold<int>(0, (s, t) => s + t.transaction.amount);

      if (firstHalf > 0 && secondHalf > 0) {
        final pct = (((secondHalf - firstHalf) / firstHalf) * 100).round().abs();
        if (pct >= 5) {
          final more = secondHalf > firstHalf;
          final key = more ? 'coachWeeklyMore' : 'coachWeeklyLess';
          return _tipIfNotDismissed(
            key: 'weekly_${now.month}',
            message: S.of(context, key).replaceAll('{pct}', '$pct'),
            icon: more ? Icons.trending_up : Icons.trending_down,
          );
        }
      }
    }

    return null;
  }

  static String? _topCategory(DashboardData d) {
    if (d.expenseByCategory.isEmpty) return null;
    final sorted = d.expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static CoachingTip? _tipIfNotDismissed({
    required String key,
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? action,
  }) {
    if (_dismissed.contains(key)) return null;
    return CoachingTip(
      dismissKey: key,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      action: action,
    );
  }
}
