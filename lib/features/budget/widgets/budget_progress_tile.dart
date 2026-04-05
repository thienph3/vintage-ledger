import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';
import 'package:vintage_ledger/features/budget/models/budget_status.dart';

class BudgetProgressTile extends StatelessWidget {
  final BudgetStatus status;
  final VoidCallback? onTap;

  const BudgetProgressTile({super.key, required this.status, this.onTap});

  Color get _progressColor {
    if (status.isExceeded) return AppColors.expense;
    if (status.isNearLimit) return AppColors.accent;
    return AppColors.income;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final pct = (status.percentage * 100).clamp(0, 999).toInt();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(getCategoryIcon(status.categoryIcon), size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(status.categoryName, style: AppTextStyles.bodyBold)),
                Text('$pct%', style: AppTextStyles.caption.copyWith(color: _progressColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.percentage.clamp(0, 1),
                backgroundColor: AppColors.divider.withValues(alpha: 0.2),
                color: _progressColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${S.of(context, 'spent')}: ${AmountFormatter.formatCompactCurrency(status.spent, locale)}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  status.isExceeded
                      ? S.of(context, 'budgetExceeded')
                      : '${S.of(context, 'remaining')}: ${AmountFormatter.formatCompactCurrency(status.remaining.abs(), locale)}',
                  style: AppTextStyles.caption.copyWith(
                    color: status.isExceeded ? AppColors.expense : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
