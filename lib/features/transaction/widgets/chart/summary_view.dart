import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';

class SummaryView extends StatelessWidget {
  final int totalIncome;
  final int totalExpense;
  final int transactionCount;
  final Map<DateTime, Map<String, int>> dailyData;

  const SummaryView({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
    required this.dailyData,
  });

  @override
  Widget build(BuildContext context) {
    final net = totalIncome - totalExpense;

    String topDay = '-';
    int topAmount = 0;
    for (var entry in dailyData.entries) {
      final exp = entry.value['expense'] ?? 0;
      if (exp > topAmount) {
        topAmount = exp;
        topDay = DateFormatter.fullDate(entry.key.millisecondsSinceEpoch);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          _amountRow(S.of(context, 'totalIncome'), totalIncome, TransactionType.income),
          const Divider(),
          _amountRow(S.of(context, 'totalExpense'), totalExpense, TransactionType.expense),
          const Divider(),
          _amountRow(
              S.of(context, 'net'), net.abs(), net >= 0 ? TransactionType.income : TransactionType.expense),
          const Divider(),
          _textRow(S.of(context, 'transactionCount'),
              transactionCount.toString()),
          const Divider(),
          _textRow(
            S.of(context, 'topSpendingDay'),
            topAmount > 0 ? topDay : '-',
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, int amount, TransactionType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          AmountText(amount: amount, type: type),
        ],
      ),
    );
  }

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }
}
