import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class DebtProgressBar extends StatelessWidget {
  final int paidAmount;
  final int totalAmount;
  final bool isLend;

  const DebtProgressBar({
    super.key,
    required this.paidAmount,
    required this.totalAmount,
    this.isLend = true,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final progress = totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
    final paidStr = AmountFormatter.formatCompactCurrency(paidAmount, locale);
    final totalStr = AmountFormatter.formatCompactCurrency(totalAmount, locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? AppColors.income : AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('$paidStr / $totalStr', style: AppTextStyles.caption),
      ],
    );
  }
}
