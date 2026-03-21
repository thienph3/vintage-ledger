import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

import 'package:vintage_ledger/features/transaction/widgets/chart/chart_styles.dart';

class TrendChart extends StatelessWidget with ChartStyles {
  final Map<DateTime, Map<String, int>> dailyData;

  TrendChart({super.key, required this.dailyData});

  @override
  Widget build(BuildContext context) {
    final sortedDays = dailyData.keys.toList()..sort();

    int accIncome = 0, accExpense = 0;
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (var i = 0; i < sortedDays.length; i++) {
      accIncome += dailyData[sortedDays[i]]!['income']!;
      accExpense += dailyData[sortedDays[i]]!['expense']!;
      incomeSpots.add(FlSpot(i.toDouble(), accIncome.toDouble()));
      expenseSpots.add(FlSpot(i.toDouble(), accExpense.toDouble()));
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, right: AppSpacing.sm),
      child: LineChart(
        LineChartData(
          minY: 0,
          lineBarsData: [
            _lineBar(incomeSpots, AppColors.income),
            _lineBar(expenseSpots, AppColors.expense),
          ],
          gridData: vintageGrid,
          borderData: noBorder,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: leftTitles),
            rightTitles: noTitles,
            topTitles: noTitles,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (sortedDays.length / 5)
                    .ceilToDouble()
                    .clamp(1, double.infinity),
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

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      barWidth: 2.5,
      color: color,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
