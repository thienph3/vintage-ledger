import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';
import 'package:vintage_ledger/features/budget/widgets/budget_summary_card.dart';
import 'package:vintage_ledger/features/insights/models/insight.dart';
import 'package:vintage_ledger/features/insights/services/insight_service.dart';
import 'package:vintage_ledger/features/insights/widgets/insight_card.dart';
import 'package:vintage_ledger/features/coaching/coaching_service.dart';
import 'package:vintage_ledger/features/coaching/coaching_tip.dart';
import 'package:vintage_ledger/features/coaching/coaching_card.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  DashboardData? _dashboard;
  List<Insight> _insights = [];
  CoachingTip? _coachingTip;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final dashboard = await sl.transactionService.getDashboard();
      final streak = await sl.settingService.recordDailyUsage();
      final lastWeekTxns = await _loadLastWeek();
      final insights = InsightService.generate(dashboard, lastWeekTxns, locale);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _streak = streak;
        _insights = insights;
        _loading = false;
      });
      final budgets = await sl.budgetService.getBudgets();
      if (!mounted) return;
      final tip = await CoachingService.getTip(
        context: context,
        dashboard: dashboard,
        streak: streak,
        budgetCount: budgets.length,
      );
      if (mounted) setState(() => _coachingTip = tip);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<TransactionWithItems>> _loadLastWeek() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = weekStart.subtract(const Duration(milliseconds: 1));
    return sl.transactionService.getByDateRange(
      lastWeekStart.millisecondsSinceEpoch,
      lastWeekEnd.millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'tabInsights'),
      showBackButton: false,
      body: _loading
          ? const ShimmerPlaceholder()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (_insights.isNotEmpty) ...[
                    ..._insights.map((i) => InsightCard(insight: i)),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_coachingTip != null)
                    CoachingCard(
                      tip: _coachingTip!,
                      onDismissed: () => setState(() => _coachingTip = null),
                    ),
                  if (_dashboard != null)
                    LedgerCard(child: ChartSection(dashboard: _dashboard!)),
                  const SizedBox(height: AppSpacing.lg),
                  const BudgetSummaryCard(),
                  if (_streak >= 2) _buildStreakCard(),
                  if (_insights.isEmpty && _dashboard == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Text(S.of(context, 'noInsights'), style: AppTextStyles.hint, textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakCard() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            const Text('\uD83D\uDD25', style: AppTextStyles.emoji),
            const SizedBox(width: AppSpacing.sm),
            Text('$_streak ${S.of(context, 'streakDays')}', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
