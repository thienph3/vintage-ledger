import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart_section.dart';
import 'package:vintage_ledger/features/budget/widgets/budget_summary_card.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  DashboardData? _dashboard;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dashboard = await sl.transactionService.getDashboard();
      final streak = await sl.settingService.recordDailyUsage();
      if (!mounted) return;
      setState(() { _dashboard = dashboard; _streak = streak; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'tabInsights'),
      showBackButton: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (_dashboard != null)
                    LedgerCard(child: ChartSection(dashboard: _dashboard!)),
                  const SizedBox(height: AppSpacing.lg),
                  const BudgetSummaryCard(),
                  _buildSavingsHighlight(),
                  if (_streak >= 2) _buildStreakCard(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildSavingsHighlight() {
    final net = (_dashboard?.monthIncome ?? 0) - (_dashboard?.monthExpense ?? 0);
    if (net <= 0 || _dashboard == null) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: LedgerCard(
        child: Row(
          children: [
            const Text('\uD83C\uDF89', style: TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${S.of(context, 'savedThisMonth')} ${AmountFormatter.formatCompactCurrency(net, locale)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.income),
              ),
            ),
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
            const Text('\uD83D\uDD25', style: TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$_streak ${S.of(context, 'streakDays')}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
