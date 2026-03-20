import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/s.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../services/transaction_service.dart';

class ChartSectionV2 extends StatelessWidget {
  final int? walletId;
  final List<TransactionWithItems> transactions;

  const ChartSectionV2({
    super.key,
    this.walletId,
    required this.transactions,
  });

  /// Nhóm transactions theo ngày
  Map<DateTime, Map<String, int>> groupByDay(List<TransactionWithItems> tx) {
    Map<DateTime, Map<String, int>> data = {};
    for (var t in tx) {
      final date = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      final day = DateTime(date.year, date.month, date.day);
      data.putIfAbsent(day, () => {"income": 0, "expense": 0});
      data[day]![t.transaction.type] =
          data[day]![t.transaction.type]! + t.transaction.amount;
    }
    return data;
  }

  /// Chuyển thành FlSpot với jitter để nét vẽ "hand-drawn"
  List<FlSpot> toFlSpots(Map<DateTime, Map<String, int>> data, String type) {
    final sorted = data.keys.toList()..sort();
    final rand = Random();
    return [
      for (var d in sorted)
        FlSpot(
          d.millisecondsSinceEpoch.toDouble(),
          data[d]![type]!.toDouble() +
              rand.nextDouble() * 5 -
              2.5, // ±2.5px jitter
        )
    ];
  }

  /// Chuyển dữ liệu thành BarChartGroupData
  List<BarChartGroupData> toBarGroups(Map<DateTime, Map<String, int>> data) {
    final sorted = data.keys.toList()..sort();
    return [
      for (var d in sorted)
        BarChartGroupData(
          x: d.millisecondsSinceEpoch.toInt(),
          barRods: [
            BarChartRodData(
              toY: data[d]!["income"]!.toDouble(),
              color: AppColors.income.withValues(alpha: 0.7),
              width: 10,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: data[d]!["expense"]!.toDouble(),
              color: AppColors.expense.withValues(alpha: 0.7),
              width: 10,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
          barsSpace: 4,
        )
    ];
  }

  String formatDate(double timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    return "${dt.day}/${dt.month}";
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(child: Text(S.of(context, 'noData')));
    }

    final now = DateTime.now();

    // Lọc transactions trong tháng
    final monthTx = transactions.where((t) {
      final d = DateTime.fromMillisecondsSinceEpoch(t.transaction.date);
      return d.year == now.year && d.month == now.month;
    }).toList();

    final dailyData = groupByDay(monthTx);
    final incomeSpots = toFlSpots(dailyData, "income");
    final expenseSpots = toFlSpots(dailyData, "expense");
    final barGroups = toBarGroups(dailyData);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E7), // giấy vintage
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.inkBlue,
              unselectedLabelColor: Colors.brown,
              tabs: [
                Tab(text: S.of(context, 'trend')),
                Tab(text: S.of(context, 'monthlyIncomeExpense')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  // Line chart vintage
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            // isCurved: true,
                            color: Colors.brown.shade700,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, xPerc, bar, index, {size}) {
                                final jitter = (Random().nextDouble() - 0.5) * 4;
                                return FlDotCirclePainter(
                                  radius: 4 + jitter,
                                  color: bar.color ?? Colors.brown,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.brown,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.brown.withValues(alpha: 0.1),
                            ),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            // isCurved: true,
                            color: Colors.red.shade700,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, xPerc, bar, index, {size}) {
                                final jitter = (Random().nextDouble() - 0.5) * 4;
                                return FlDotCirclePainter(
                                  radius: 4 + jitter,
                                  color: bar.color ?? Colors.brown,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.brown,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withValues(alpha: .1),
                            ),
                          ),
                        ],
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          drawHorizontalLine: true,
                          getDrawingHorizontalLine: (v) => FlLine(
                              color: Colors.brown.shade200,
                              strokeWidth: 0.5,
                              dashArray: [4, 4]),
                          getDrawingVerticalLine: (v) => FlLine(
                              color: Colors.brown.shade200,
                              strokeWidth: 0.5,
                              dashArray: [4, 4]),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.brown),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Text(
                                formatDate(value),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.brown),
                              ),
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
                  ),
                  // Bar chart vintage
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (v) => FlLine(
                              color: Colors.brown.shade200,
                              strokeWidth: 0.5,
                              dashArray: [4, 4]),
                          getDrawingVerticalLine: (v) => FlLine(
                              color: Colors.brown.shade200,
                              strokeWidth: 0.5,
                              dashArray: [4, 4]),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (v, meta) => Text(
                                      v.toInt().toString(),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.brown),
                                    )),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Text(
                                formatDate(value),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.brown),
                              ),
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}