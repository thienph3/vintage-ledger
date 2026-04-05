import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';

class BreakdownChart extends StatelessWidget {
  final Map<String, int> expenseByCategory;

  const BreakdownChart({super.key, required this.expenseByCategory});

  static const pieColors = [
    AppColors.primary,
    AppColors.expense,
    AppColors.income,
    AppColors.accent,
    AppColors.divider,
    AppColors.textSecondary,
    AppColors.textPrimary,
  ];

  @override
  Widget build(BuildContext context) {
    if (expenseByCategory.isEmpty) {
      return EmptyState(message: S.of(context, 'noData'));
    }

    final total = expenseByCategory.values.fold(0, (s, v) => s + v);
    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = List.generate(entries.length, (i) {
      final pct = entries[i].value / total * 100;
      return PieChartSectionData(
        value: entries[i].value.toDouble(),
        color: pieColors[i % pieColors.length],
        radius: 40,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      );
    });

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(entries.length, (i) {
              final pct =
                  (entries[i].value / total * 100).toStringAsFixed(0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: pieColors[i % pieColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entries[i].key,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$pct%', style: AppTextStyles.caption),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
