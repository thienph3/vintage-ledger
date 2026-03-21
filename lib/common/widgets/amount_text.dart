import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class AmountText extends StatelessWidget {
  final int amount;
  final String type;
  final double? fontSize;
  final bool compact;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.fontSize,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final color = type == 'income' ? AppColors.income : AppColors.expense;
    final sign = type == 'income' ? '' : '-';
    final formatted = compact
        ? AmountFormatter.formatCompactCurrency(amount, locale)
        : AmountFormatter.formatCurrency(amount, locale);

    return Text(
      '$sign$formatted',
      style: AppTextStyles.amount.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? 16,
      ),
    );
  }
}
