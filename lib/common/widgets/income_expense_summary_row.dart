import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';

class IncomeExpenseSummaryRow extends StatelessWidget {
  final int income;
  final int expense;
  final String? incomeLabel;
  final String? expenseLabel;

  const IncomeExpenseSummaryRow({
    super.key,
    required this.income,
    required this.expense,
    this.incomeLabel,
    this.expenseLabel,
  });

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
