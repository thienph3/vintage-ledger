import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

mixin ChartStyles {
  FlGridData get vintageGrid => FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.divider,
          strokeWidth: 0.5,
          dashArray: [4, 4],
        ),
      );

  FlBorderData get noBorder => FlBorderData(show: false);

  AxisTitles get noTitles =>
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  SideTitles get leftTitles => SideTitles(
        showTitles: true,
        reservedSize: 46,
        getTitlesWidget: (value, _) =>
            Text(compactAmount(value), style: AppTextStyles.caption),
      );

  String compactAmount(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toInt().toString();
  }
}
