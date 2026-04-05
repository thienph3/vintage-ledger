import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

import 'package:vintage_ledger/features/transaction/widgets/chart/chart_styles.dart';

class DailyChart extends StatelessWidget with ChartStyles {
  final Map<DateTime, Map<String, int>> dailyData;

  DailyChart({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    final sortedDays = dailyData.keys.toList()..sort();

    final groups = List.generate(sortedDays.length, (i) {
      final d = dailyData[sortedDays[i]]!;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: d['income']!.toDouble(),
            color: AppColors.income.withValues(alpha: 0.7),
            width: 6,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: d['expense']!.toDouble(),
            color: AppColors.expense.withValues(alpha: 0.7),
            width: 6,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 2,
      );
    });

    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, right: AppSpacing.sm),
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: vintageGrid,
          borderData: noBorder,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: leftTitlesFor(locale)),
            rightTitles: noTitles,
            topTitles: noTitles,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sortedDays.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(
                      DateFormatter.date(
                          sortedDays[idx].millisecondsSinceEpoch),
                      style: AppTextStyles.caption,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ),
    );
  }
}
