import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/common/widgets/income_expense_summary_row.dart';
import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class MonthlyInsightScreen extends StatefulWidget {
  const MonthlyInsightScreen({super.key});

  @override
  State<MonthlyInsightScreen> createState() => _MonthlyInsightScreenState();
}

class _MonthlyInsightScreenState extends State<MonthlyInsightScreen> {
  DashboardData? _current;
  Map<String, int>? _lastMonthByCategory;
  int _lastMonthExpense = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final current = await sl.transactionService.getDashboard();

      // Last month data
      final now = DateTime.now();
      final lastStart = DateTime(now.year, now.month - 1, 1);
      final lastEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      final lastMonth = await sl.transactionService.getByDateRange(
        lastStart.millisecondsSinceEpoch, lastEnd.millisecondsSinceEpoch,
      );

      final lastByCategory = <String, int>{};
      int lastExpense = 0;
      for (final t in lastMonth) {
        if (t.transaction.type != TransactionType.expense) continue;
        final catId = t.transaction.categoryId;
        final catName = current.categoryMap[catId]?.name ?? '?';
        lastByCategory[catName] = (lastByCategory[catName] ?? 0) + t.transaction.amount;
        lastExpense += t.transaction.amount;
      }

      if (!mounted) return;
      setState(() {
        _current = current;
        _lastMonthByCategory = lastByCategory;
        _lastMonthExpense = lastExpense;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'monthlyInsight'),
      body: _loading
          ? const ShimmerPlaceholder()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: AppSpacing.md),
                _buildHighlight(),
                const SizedBox(height: AppSpacing.md),
                _buildVsLastMonth(),
                const SizedBox(height: AppSpacing.md),
                _buildTopSpending(),
                const SizedBox(height: AppSpacing.md),
                _buildSpendingComparison(),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    return LedgerCard(
      child: Column(
        children: [
          IncomeExpenseSummaryRow(
            income: _current?.monthIncome ?? 0,
            expense: _current?.monthExpense ?? 0,
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.of(context, 'net'), style: AppTextStyles.body),
              AmountText.fromBalance(balance: (_current?.monthIncome ?? 0) - (_current?.monthExpense ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight() {
    final currentExp = _current?.monthExpense ?? 0;
    final diff = currentExp - _lastMonthExpense;
    if (_lastMonthExpense == 0) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).languageCode;
    final saved = diff < 0;

    return LedgerCard(
      child: Row(
        children: [
          Icon(
            saved ? Icons.celebration : Icons.trending_up,
            color: saved ? AppColors.income : AppColors.expense,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              saved
                  ? '${S.of(context, 'savedThisMonth')} ${AmountFormatter.formatCompactCurrency(diff.abs(), locale)} \uD83C\uDF89'
                  : '${S.of(context, 'spentMoreThisMonth')} ${AmountFormatter.formatCompactCurrency(diff.abs(), locale)}',
              style: AppTextStyles.body.copyWith(
                color: saved ? AppColors.income : AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsLastMonth() {
    final currentExp = _current?.monthExpense ?? 0;
    final diff = currentExp - _lastMonthExpense;
    final isMore = diff > 0;
    final locale = Localizations.localeOf(context).languageCode;

    return LedgerCard(
      child: Row(
        children: [
          Expanded(
            child: Text(S.of(context, 'vsLastMonth'), style: AppTextStyles.body),
          ),
          Icon(
            isMore ? Icons.trending_up : Icons.trending_down,
            color: isMore ? AppColors.expense : AppColors.income,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${isMore ? '+' : '-'}${AmountFormatter.formatCompactCurrency(diff.abs(), locale)}',
            style: AppTextStyles.bodyBold.copyWith(
              color: isMore ? AppColors.expense : AppColors.income,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpending() {
    final entries = (_current?.expenseByCategory ?? {}).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = entries.take(3);
    final locale = Localizations.localeOf(context).languageCode;

    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context, 'topSpending'), style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (top3.isEmpty)
            Text('-', style: AppTextStyles.hint),
          ...top3.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(e.key, style: AppTextStyles.body)),
                Text(
                  AmountFormatter.formatCompactCurrency(e.value, locale),
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.expense),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Task #9: Spending comparison bar chart (this month vs last month per category)
  Widget _buildSpendingComparison() {
    final currentMap = _current?.expenseByCategory ?? {};
    final lastMap = _lastMonthByCategory ?? {};
    final allCategories = {...currentMap.keys, ...lastMap.keys};
    if (allCategories.isEmpty) return const SizedBox.shrink();

    final maxAmount = [...currentMap.values, ...lastMap.values]
        .fold<int>(1, (a, b) => a > b ? a : b);

    return LedgerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context, 'expense')} ${S.of(context, 'vsLastMonth')}', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _legendDot(AppColors.expense, S.of(context, 'byMonth')),
              const SizedBox(width: AppSpacing.md),
              _legendDot(AppColors.divider, S.of(context, 'vsLastMonth')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...allCategories.map((cat) {
            final current = currentMap[cat] ?? 0;
            final last = lastMap[cat] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat, style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  _bar(current, maxAmount, AppColors.expense),
                  const SizedBox(height: AppSpacing.xs),
                  _bar(last, maxAmount, AppColors.divider),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _bar(int value, int max, Color color) {
    final ratio = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(height: 8, decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4),
            )),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
