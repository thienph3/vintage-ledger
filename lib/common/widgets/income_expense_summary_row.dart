import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class IncomeExpenseSummaryRow extends StatelessWidget {
  final int income;
  final int expense;
  final String? incomeLabel;
  final String? expenseLabel;
  final bool showNet;
  final String? netLabel;

  const IncomeExpenseSummaryRow({
    super.key,
    required this.income,
    required this.expense,
    this.incomeLabel,
    this.expenseLabel,
    this.showNet = false,
    this.netLabel,
  });

  static Color netColor(int net) {
    if (net > 0) return AppColors.income;
    if (net < 0) return AppColors.expense;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                incomeLabel ?? S.of(context, 'totalIncome'),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.xs),
              AmountText(amount: income, type: TransactionType.income),
            ],
          ),
        ),
        Container(width: 1, height: 40, color: AppColors.divider),
        Expanded(
          child: Column(
            children: [
              Text(
                expenseLabel ?? S.of(context, 'totalExpense'),
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.xs),
              AmountText(amount: expense, type: TransactionType.expense),
            ],
          ),
        ),
        if (showNet) ...[
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: Column(
              children: [
                Text(
                  netLabel ?? S.of(context, 'net'),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${net > 0 ? '+' : net < 0 ? '-' : ''}${AmountFormatter.formatCompactCurrency(net.abs(), Localizations.localeOf(context).languageCode)}',
                  style: AppTextStyles.amount.copyWith(
                    color: netColor(net),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
