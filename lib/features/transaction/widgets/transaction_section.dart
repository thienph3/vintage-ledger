import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/widgets/transaction_feed_item.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class TransactionSection extends StatelessWidget {
  final String? walletId;
  final List<TransactionWithItems> transactions;
  final Map<String, Category> categoryMap;
  final VoidCallback onDataChanged;

  const TransactionSection({
    super.key,
    this.walletId,
    required this.transactions,
    required this.categoryMap,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context, 'recentTransactions'), style: AppTextStyles.titleSmall),
            InkWell(
              onTap: () => context.pushScreen(TransactionListScreen(walletId: walletId)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context, 'viewAll'), style: AppTextStyles.link),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (transactions.isEmpty)
          EmptyState(emoji: '📝', message: S.of(context, 'emptyTransactionHint')),
        ...transactions.map((txn) => TransactionFeedItem(
          txn: txn,
          categoryName: categoryMap[txn.transaction.categoryId]?.name ?? S.of(context, 'other'),
          onChanged: onDataChanged,
        )),
      ],
    );
  }
}
