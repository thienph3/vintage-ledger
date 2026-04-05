import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/feed/feed_helper.dart';
import 'package:vintage_ledger/features/feed/widgets/feed_item.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/transaction/screens/transaction_form_screen.dart';
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

  const TransactionFeedItem({
    super.key,
    required this.txn,
    required this.categoryName,
    this.onChanged,
    this.timeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final actor = FeedHelper.resolveName(txn.transaction.createdBy, S.of(context, 'youActor'));
    final story = TransactionStory.format(
      actorName: actor,
      categoryName: categoryName,
      amount: txn.transaction.amount,
      type: txn.transaction.type,
      locale: locale,
      note: txn.transaction.note,
    );
    final time = timeFormatter != null
        ? timeFormatter!(txn.transaction.date)
        : DateFormatter.short(txn.transaction.date);

    return Column(
      children: [
        FeedItem(
          actorName: actor,
          text: story,
          time: time,
          photoUrl: FeedHelper.resolvePhoto(txn.transaction.createdBy),
          onTap: () async {
            final result = await context.pushScreen(TransactionFormScreen(
              walletId: txn.transaction.walletId,
              existing: txn,
            ));
            if (result == true) onChanged?.call();
          },
        ),
        if (txn.transaction.id != null)
          StreamBuilder<Map<String, String>>(
            stream: sl.reactionService.watchReactions(txn.transaction.id!),
            builder: (context, snap) {
              final reactions = snap.data ?? {};
              return GestureDetector(
                onLongPress: () async {
                  final emoji = await ReactionPicker.show(context);
                  if (emoji != null) {
                    sl.reactionService.addReaction(txn.transaction.id!, emoji);
                  }
                },
                child: ReactionBar(reactions: reactions),
              );
            },
          ),
      ],
    );
  }
}
