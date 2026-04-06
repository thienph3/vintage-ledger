import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class GoalProgressBar extends StatelessWidget {
  final String name;
  final String? emoji;
  final int savedAmount;
  final int targetAmount;
  final int? daysLeft;
  final bool compact;

  const GoalProgressBar({
    super.key,
    required this.name,
    this.emoji,
    required this.savedAmount,
    required this.targetAmount,
    this.daysLeft,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final progress = targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toInt();
    final savedStr = AmountFormatter.formatCompactCurrency(savedAmount, locale);
    final targetStr = AmountFormatter.formatCompactCurrency(targetAmount, locale);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 12)),
              if (emoji != null) const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('$savedStr/$targetStr', style: AppTextStyles.caption)),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(progress >= 1.0 ? AppColors.income : AppColors.primary),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (emoji != null) Text(emoji!, style: AppTextStyles.emoji),
              if (emoji != null) const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(name, style: AppTextStyles.bodyBold)),
              Text('$pct%', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$savedStr / $targetStr', style: AppTextStyles.caption),
              if (daysLeft != null)
                Text(
                  daysLeft! >= 0 ? 'Còn $daysLeft ngày' : 'Quá hạn ${-daysLeft!} ngày',
                  style: AppTextStyles.caption.copyWith(
                    color: daysLeft! < 0 ? AppColors.expense : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
