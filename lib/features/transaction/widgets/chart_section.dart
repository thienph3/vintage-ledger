import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';

import 'package:vintage_ledger/features/transaction/models/dashboard_data.dart';

import 'package:vintage_ledger/features/transaction/widgets/chart/chart_view.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/trend_chart.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/daily_chart.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/breakdown_chart.dart';
import 'package:vintage_ledger/features/transaction/widgets/chart/summary_view.dart';

class ChartSection extends StatefulWidget {
  final DashboardData dashboard;

  const ChartSection({super.key, required this.dashboard});

  @override
  State<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<ChartSection> {
  ChartView _view = ChartView.trend;

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
          height: 250,
          child: widget.dashboard.monthly.isEmpty
              ? EmptyState(message: S.of(context, 'emptyChartHint'))
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

  static const _legendHeight = 20.0;

  Widget _buildLegend() {
    return SizedBox(
      height: _legendHeight,
      child: switch (_view) {
        ChartView.summary => const SizedBox.shrink(),
        ChartView.breakdown => _breakdownLegend(),
        _ => Row(
            children: [
              _legendDot(AppColors.income, S.of(context, 'income')),
              const SizedBox(width: AppSpacing.md),
              _legendDot(AppColors.expense, S.of(context, 'expense')),
            ],
          ),
      },
    );
  }

  Widget _breakdownLegend() {
    final keys = widget.dashboard.expenseByCategory.keys.toList();
    if (keys.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: keys.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, i) => _legendDot(
        BreakdownChart.pieColors[i % BreakdownChart.pieColors.length],
        keys[i],
      ),
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
    final d = widget.dashboard;
    switch (_view) {
      case ChartView.trend:
        return TrendChart(key: const ValueKey('trend'), dailyData: d.dailyData);
      case ChartView.daily:
        return DailyChart(key: const ValueKey('daily'), dailyData: d.dailyData);
      case ChartView.breakdown:
        return BreakdownChart(
            key: const ValueKey('breakdown'),
            expenseByCategory: d.expenseByCategory);
      case ChartView.summary:
        return SummaryView(
          key: const ValueKey('summary'),
          totalIncome: d.monthIncome,
          totalExpense: d.monthExpense,
          transactionCount: d.monthly.length,
          dailyData: d.dailyData,
        );
    }
  }
}
