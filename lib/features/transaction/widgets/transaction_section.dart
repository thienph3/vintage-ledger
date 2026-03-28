import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/screens/category_list_screen.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/amount_text.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';

import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class TransactionSection extends StatelessWidget {
  final int? walletId;
  final List<TransactionWithItems> transactions;
  final Map<int, Category> categoryMap;

  final Future<void> Function() onAddTransaction;
  final Future<void> Function(TransactionWithItems transaction)
  onTapTransaction;
  final Future<void> Function(TransactionWithItems transaction)
  onDeleteTransaction;

  const TransactionSection({
    super.key,
    this.walletId,
    required this.transactions,
    required this.categoryMap,
    required this.onAddTransaction,
    required this.onTapTransaction,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.of(context, 'recentTransactions'),
              style: AppTextStyles.title,
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionListScreen(walletId: walletId),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context, 'viewAll'), style: AppTextStyles.link),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(S.of(context, 'date'), style: AppTextStyles.body),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      S.of(context, 'category'),
                      style: AppTextStyles.columnHeader,
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_outward, size: 16),
                  ],
                ),
              ),
            ),
            SizedBox(
              child: Text(
                S.of(context, 'amount'),
                textAlign: TextAlign.right,
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
        const Divider(),

        if (transactions.isEmpty)
          EmptyState(message: S.of(context, 'noTransactions')),
        if (transactions.isNotEmpty)
          ...transactions.map((transaction) {
            final category = categoryMap[transaction.transaction.categoryId];
            return InkWell(
              onTap: () async => await onTapTransaction(transaction),
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(S.of(context, 'deleteTransaction')),
                    content: Text(S.of(context, 'deleteTransactionConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.of(context, 'cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(S.of(context, 'delete')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await onDeleteTransaction(transaction);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        DateFormatter.short(transaction.transaction.date),
                        style: AppTextStyles.body,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (category?.icon != null) ...[
                            Icon(
                              getCategoryIcon(category?.icon),
                              size: 20,
                              color: AppColors.inkBlue,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            category?.name ?? S.of(context, 'other'),
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      child: AmountText(
                        amount: transaction.transaction.amount,
                        type: transaction.transaction.type,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddTransaction,
            icon: const Icon(Icons.add, size: 16),
            label: Text(S.of(context, 'addTransaction')),
          ),
        ),
      ],
    );
  }
}
