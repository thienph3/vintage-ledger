// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';
import 'package:vintage_ledger/features/feed/widgets/feed_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/screens/income_expense_form_screen.dart';
import 'package:vintage_ledger/features/transfer/screens/transfer_form_screen.dart';
import 'package:vintage_ledger/features/transaction/widgets/reaction_bar.dart';
import 'package:vintage_ledger/features/transaction/widgets/reaction_picker.dart';
import 'package:vintage_ledger/utils/date_formatter.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';
import 'package:vintage_ledger/utils/transaction_story.dart';

class TransactionFeedItem extends StatelessWidget {
  final TransactionWithItems txn;
  final String categoryName;
  final VoidCallback? onChanged;
  final String Function(int)? timeFormatter;
  final Map<String, String> walletNames;

  const TransactionFeedItem({
    super.key,
    required this.txn,
    required this.categoryName,
    this.onChanged,
    this.timeFormatter,
    this.walletNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final actor = FeedHelper.resolveName(txn.transaction.createdBy, S.of(context, 'youActor'));
    final t = txn.transaction;

    final story = TransactionStory.format(
      actorName: actor,
      categoryName: categoryName,
      amount: t.amount,
      type: t.type,
      locale: locale,
      note: t.note,
      walletName: walletNames[t.walletId],
      toWalletName: t.toWalletName ?? walletNames[t.toWalletId],
      toAccountName: t.toAccountName,
    );
    final time = timeFormatter != null
        ? timeFormatter!(t.date)
        : DateFormatter.short(t.date);

    final content = Column(
      children: [
        FeedItem(
          actorName: actor,
          text: story,
          time: time,
          photoUrl: FeedHelper.resolvePhoto(t.createdBy),
          onTap: () async {
            final Widget target = t.type.isTransfer
                ? TransferFormScreen(existing: txn)
                : IncomeExpenseFormScreen(walletId: t.walletId, existing: txn);
            final result = await context.pushScreen(target);
            if (result == true) onChanged?.call();
          },
        ),
        if (t.id != null)
          StreamBuilder<Map<String, String>>(
            stream: sl.reactionService.watchReactions(t.id!),
            builder: (context, snap) {
              final reactions = snap.data ?? {};
              return GestureDetector(
                onLongPress: () async {
                  final emoji = await ReactionPicker.show(context);
                  if (emoji != null) {
                    sl.reactionService.addReaction(t.id!, emoji);
                  }
                },
                child: ReactionBar(reactions: reactions),
              );
            },
          ),
      ],
    );

    if (t.id == null) return content;

    return SwipeListItem(
      itemKey: ValueKey(t.id),
      confirmDelete: () => showDeleteConfirmation(
        context,
        titleKey: 'deleteTransaction',
        contentKey: 'deleteTransactionConfirm',
      ),
      onDelete: () async {
        await sl.transactionService.deleteTransaction(t.id!);
        onChanged?.call();
      },
      child: content,
    );
  }
}
