import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';

class ChartSection extends StatelessWidget {
  final List<TransactionWithItems> transactions;

  const ChartSection({super.key, required this.transactions});

  Map<DateTime, Map<String, int>> groupByDayByType(
    List<TransactionWithItems> tx,
  ) {
    Map<DateTime, Map<String, int>> data = {};
    for (var t in tx) {
      final date = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      final day = DateTime(date.year, date.month, date.day);
      data.putIfAbsent(day, () => {"income": 0, "expense": 0});
      if (t.transaction.type == "income") {
        data[day]!["income"] = data[day]!["income"]! + t.transaction.amount;
      } else {
        data[day]!["expense"] = data[day]!["expense"]! + t.transaction.amount;
      }
    }
    return data;
  }

  Map<DateTime, Map<String, int>> accumulateByType(
    Map<DateTime, Map<String, int>> dailyData,
  ) {
    final sortedKeys = dailyData.keys.toList()..sort();
    int accumulatedIncome = 0;
    int accumulatedExpense = 0;
    Map<DateTime, Map<String, int>> accumulated = {};
    for (var key in sortedKeys) {
      accumulatedIncome += dailyData[key]!["income"]!;
      accumulatedExpense += dailyData[key]!["expense"]!;
      accumulated[key] = {
        "income": accumulatedIncome,
        "expense": accumulatedExpense,
      };
    }
    return accumulated;
  }

  List<FlSpot> mapToSpotsByType(
    Map<DateTime, Map<String, int>> data,
    String type,
  ) {
    final sortedKeys = data.keys.toList()..sort();
    return sortedKeys
        .map(
          (k) => FlSpot(
            k.millisecondsSinceEpoch.toDouble(),
            data[k]![type]!.toDouble(),
          ),
        )
        .toList();
  }

  List<BarChartGroupData> mapToMonthlyBarGroups(
    Map<DateTime, Map<String, int>> data,
  ) {
    final sortedKeys = data.keys.toList()..sort();
    return sortedKeys
        .map(
          (k) => BarChartGroupData(
            x: k.millisecondsSinceEpoch.toInt(),
            barRods: [
              BarChartRodData(
                toY: data[k]!["income"]!.toDouble(),
                color: AppColors.income,
                width: 8,
              ),
              BarChartRodData(
                toY: data[k]!["expense"]!.toDouble(),
                color: AppColors.expense,
                width: 8,
              ),
            ],
            barsSpace: 2,
          ),
        )
        .toList();
  }

  String formatDate(double timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty)
      return Center(child: Text(S.of(context, 'noData')));

    final now = DateTime.now();

    final monthlyDataByType = groupByDayByType(
      transactions.where((t) {
        final date = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
        return date.year == now.year && date.month == now.month;
      }).toList(),
    );

    final accumulatedData = accumulateByType(monthlyDataByType);
    final incomeSpots = mapToSpotsByType(accumulatedData, "income");
    final expenseSpots = mapToSpotsByType(accumulatedData, "expense");
    final monthlyGroups = mapToMonthlyBarGroups(monthlyDataByType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 300,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.inkBlue,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: S.of(context, 'trend')),
                    Tab(text: S.of(context, 'monthlyIncomeExpense')),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: incomeSpots,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                color: AppColors.income,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.income.withValues(
                                    alpha: 0.3,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.income.withValues(alpha: 0.3),
                                      AppColors.income.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              LineChartBarData(
                                spots: expenseSpots,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                color: AppColors.expense,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.expense.withValues(
                                    alpha: 0.3,
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.expense.withValues(alpha: 0.3),
                                      AppColors.expense.withValues(alpha: 0.0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            borderData: FlBorderData(
                              show: false,
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.divider,
                                  width: 1,
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.divider,
                                strokeWidth: 0.5,
                                dashArray: [4, 4],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  interval:
                                      [...incomeSpots, ...expenseSpots]
                                              .map((e) => e.y)
                                              .fold(
                                                0.0,
                                                (a, b) => a > b ? a : b,
                                              ) /
                                          5 +
                                      1,
                                  getTitlesWidget: (value, meta) {
                                    String text;

                                    if (value >= 1000000) {
                                      text =
                                          "${(value / 1000000).toStringAsFixed(1)}m";
                                    } else if (value >= 1000) {
                                      text =
                                          "${(value / 1000).toStringAsFixed(0)}k";
                                    } else {
                                      text = value.toInt().toString();
                                    }

                                    return Text(
                                      text,
                                      style: AppTextStyles.caption,
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final date =
                                        DateTime.fromMillisecondsSinceEpoch(
                                          value.toInt(),
                                        );
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 6,
                                      child: Text(
                                        "${date.day}/${date.month}",
                                        style: AppTextStyles.caption,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: BarChart(
                          BarChartData(
                            barGroups: monthlyGroups,
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  reservedSize: 44,
                                  showTitles: true,
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) =>
                                      SideTitleWidget(
                                        meta: meta,
                                        space: 6,
                                        child: Text(
                                          formatDate(value),
                                          style: AppTextStyles.caption,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
