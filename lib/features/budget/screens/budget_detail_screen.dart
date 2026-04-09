import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';
import 'package:vintage_ledger/features/budget/widgets/budget_progress_tile.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

class BudgetDetailScreen extends StatefulWidget {
  final BudgetStatus status;

  const BudgetDetailScreen({super.key, required this.status});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  List<({String note, int amount, int date})> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txns = await sl.budgetService.getBudgetTransactions(
      widget.status.budget.categoryId,
      widget.status.periodStart,
      widget.status.periodEnd,
    );
    if (!mounted) return;
    setState(() { _transactions = txns; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final s = widget.status;
    final periodLabel = '${s.periodStart.day}/${s.periodStart.month} – ${s.periodEnd.day}/${s.periodEnd.month}';

    return AppScaffold(
      title: s.categoryName,
      body: _loading
          ? const ShimmerPlaceholder()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Budget progress summary
                LedgerCard(
                  child: Column(
                    children: [
                      BudgetProgressTile(status: s),
                      const SizedBox(height: AppSpacing.sm),
                      Text(periodLabel, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Transaction list
                Text(
                  '${S.of(context, 'recentTransactions')} (${_transactions.length})',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text(S.of(context, 'noTransactions'), style: AppTextStyles.hint)),
                  ),
                ..._transactions.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: LedgerCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.note.isNotEmpty ? t.note : s.categoryName,
                                style: AppTextStyles.body,
                              ),
                              Text(
                                DateFormatter.fullDate(t.date),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AmountFormatter.formatCompactCurrency(t.amount, locale),
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.expense),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
    );
  }
}
