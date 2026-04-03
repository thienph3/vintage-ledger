import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/utils/transaction_story.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_list_screen.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/service_locator.dart';

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
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (transactions.isEmpty)
          EmptyState(emoji: '📝', message: S.of(context, 'emptyTransactionHint')),
        ...transactions.map((txn) => _buildItem(context, txn)),
      ],
    );
  }

  Widget _buildItem(BuildContext context, TransactionWithItems txn) {
    final cat = categoryMap[txn.transaction.categoryId];
    final catName = cat?.name ?? S.of(context, 'other');
    final locale = Localizations.localeOf(context).languageCode;
    final actor = FeedHelper.resolveName(txn.transaction.createdBy, S.of(context, 'youActor'));
    final story = TransactionStory.format(
      actorName: actor,
      categoryName: catName,
      amount: txn.transaction.amount,
      type: txn.transaction.type,
      locale: locale,
      note: txn.transaction.note,
    );
    final time = DateFormatter.short(txn.transaction.date);

    return InkWell(
      onTap: () async {
        final result = await context.pushScreen(TransactionFormScreen(
          walletId: txn.transaction.walletId,
          existing: txn,
        ));
        if (result == true) onDataChanged();
      },
      onLongPress: () async {
        final confirm = await showDeleteConfirmation(context, titleKey: 'deleteTransaction', contentKey: 'deleteTransactionConfirm');
        if (confirm == true) {
          await sl.transactionService.deleteTransaction(txn.transaction.id!);
          onDataChanged();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(child: Text(story, style: AppTextStyles.body)),
            Text(time, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
