import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/screens/budget_list_screen.dart';
import 'package:vintage_ledger/features/budget/screens/monthly_insight_screen.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

class BudgetSummaryCard extends StatefulWidget {
  const BudgetSummaryCard({super.key});

  @override
  State<BudgetSummaryCard> createState() => _BudgetSummaryCardState();
}

class _BudgetSummaryCardState extends State<BudgetSummaryCard> {
  List<BudgetStatus> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final statuses = await sl.budgetService.getBudgetStatuses();
      if (!mounted) return;
      // Chỉ hiện budgets gần/vượt limit
      setState(() => _alerts = statuses.where((s) => s.isNearLimit || s.isExceeded).toList());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context, 'budget'), style: AppTextStyles.titleSmall),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => context.pushScreen(const MonthlyInsightScreen()),
                    child: const Icon(Icons.insights, size: 20, color: AppColors.inkBlue),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: () async {
                      await context.pushScreen(const BudgetListScreen());
                      _load();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(S.of(context, 'viewAll'), style: AppTextStyles.link),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_alerts.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () async {
                await context.pushScreen(const BudgetListScreen());
                _load();
              },
              child: Text(S.of(context, 'emptyBudgetHint'), style: AppTextStyles.hint),
            ),
          ],
          ..._alerts.map((s) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  s.isExceeded ? Icons.warning_amber : Icons.info_outline,
                  size: 16,
                  color: s.isExceeded ? AppColors.expense : const Color(0xFFE6A817),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    s.isExceeded
                        ? '${s.categoryName}: ${S.of(context, 'budgetExceeded')}'
                        : '${s.categoryName}: ${S.of(context, 'remaining')} ${AmountFormatter.formatCompactCurrency(s.remaining, locale)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: s.isExceeded ? AppColors.expense : null,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
