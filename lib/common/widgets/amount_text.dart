import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class AmountText extends StatelessWidget {
  final int amount;
  final TransactionType type;
  final String currency;
  final double? fontSize;
  final bool compact;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.currency = 'VND',
    this.fontSize,
    this.compact = false,
  });

  static Widget fromBalance({
    Key? key,
    required int balance,
    String currency = 'VND',
    double? fontSize,
    bool compact = false,
  }) {
    return AmountText(
      key: key,
      amount: balance.abs(),
      type: balance >= 0 ? TransactionType.income : TransactionType.expense,
      currency: currency,
      fontSize: fontSize,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final color = type.isIncome ? AppColors.income : AppColors.expense;
    final sign = type.isIncome ? '' : '-';
    final formatted = compact
        ? AmountFormatter.formatCompactCurrency(amount, locale, currencyCode: currency)
        : AmountFormatter.formatCurrency(amount, locale, currencyCode: currency);

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
