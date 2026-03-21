import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';

import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

import 'package:vintage_ledger/features/transaction/widgets/chart/chart_view.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/trend_chart.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/daily_chart.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/breakdown_chart.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/summary_view.dart';

class ChartSection extends StatefulWidget {
  final List<TransactionWithItems> transactions;
  final Map<int, Category> categoryMap;

  const ChartSection({
    super.key,
    required this.transactions,
    required this.categoryMap,
  });

  @override
  State<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<ChartSection> {
  ChartView _view = ChartView.trend;

  // ── Data helpers ──

  Map<DateTime, Map<String, int>> get _dailyData {
    final map = <DateTime, Map<String, int>>{};
    for (var t in widget.transactions) {
      final dt = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      final day = DateTime(dt.year, dt.month, dt.day);
      map.putIfAbsent(day, () => {'income': 0, 'expense': 0});
      map[day]![t.transaction.type] =
          map[day]![t.transaction.type]! + t.transaction.amount;
    }
    return map;
  }

  int _totalByType(String type) => widget.transactions
      .where((t) => t.transaction.type == type)
      .fold(0, (s, t) => s + t.transaction.amount);

  Map<String, int> get _expenseByCategory {
    final map = <String, int>{};
    for (var t in widget.transactions) {
      if (t.transaction.type != 'expense') continue;
      final name = widget.categoryMap[t.transaction.categoryId]?.name ??
          S.of(context, 'uncategorized');
      map[name] = (map[name] ?? 0) + t.transaction.amount;
    }
    return map;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildViewSelector(),
        const SizedBox(height: AppSpacing.sm),
        _buildLegend(),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 240,
          child: widget.transactions.isEmpty
              ? EmptyState(message: S.of(context, 'noData'))
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _buildCurrentView(),
                ),
        ),
      ],
    );
  }

  Widget _buildViewSelector() {
    final labels = {
      ChartView.trend: S.of(context, 'chartTrend'),
      ChartView.daily: S.of(context, 'chartDaily'),
      ChartView.breakdown: S.of(context, 'chartBreakdown'),
      ChartView.summary: S.of(context, 'chartSummary'),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChartView.values.map((v) {
          final selected = v == _view;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => setState(() => _view = v),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.inkBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? AppColors.inkBlue : AppColors.divider,
                  ),
                ),
                child: Text(
                  labels[v]!,
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? Colors.white : AppColors.inkBlack,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    if (_view == ChartView.summary) return const SizedBox.shrink();

    if (_view == ChartView.breakdown) {
      final categories = _expenseByCategory;
      if (categories.isEmpty) return const SizedBox.shrink();
      final keys = categories.keys.toList();
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: List.generate(keys.length, (i) {
          return _legendDot(
              BreakdownChart.pieColors[i % BreakdownChart.pieColors.length],
              keys[i]);
        }),
      );
    }

    return Row(
      children: [
        _legendDot(AppColors.income, S.of(context, 'income')),
        const SizedBox(width: AppSpacing.md),
        _legendDot(AppColors.expense, S.of(context, 'expense')),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildCurrentView() {
    final daily = _dailyData;
    switch (_view) {
      case ChartView.trend:
        return TrendChart(key: const ValueKey('trend'), dailyData: daily);
      case ChartView.daily:
        return DailyChart(key: const ValueKey('daily'), dailyData: daily);
      case ChartView.breakdown:
        return BreakdownChart(
            key: const ValueKey('breakdown'),
            expenseByCategory: _expenseByCategory);
      case ChartView.summary:
        return SummaryView(
          key: const ValueKey('summary'),
          totalIncome: _totalByType('income'),
          totalExpense: _totalByType('expense'),
          transactionCount: widget.transactions.length,
          dailyData: daily,
        );
    }
  }
}
