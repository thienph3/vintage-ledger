import 'package:vintage_ledger/core/constants/category_emojis.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

/// Structured story output for RichText rendering.
typedef StoryParts = ({String? actorName, String rest});

class TransactionStory {
  static String format({
    required String actorName,
    required String categoryName,
    required int amount,
    required TransactionType type,
    required String locale,
    String? note,
    String? walletName,
    String? toWalletName,
    String? toAccountName,
  }) {
    final parts = formatStructured(
      actorName: actorName,
      categoryName: categoryName,
      amount: amount,
      type: type,
      locale: locale,
      note: note,
      walletName: walletName,
      toWalletName: toWalletName,
      toAccountName: toAccountName,
    );
    return parts.actorName != null
        ? '${parts.actorName}${parts.rest}'
        : parts.rest;
  }

  /// Returns structured data so FeedItem can render the actor name
  /// with a distinct style.
  static StoryParts formatStructured({
    required String actorName,
    required String categoryName,
    required int amount,
    required TransactionType type,
    required String locale,
    String? note,
    String? walletName,
    String? toWalletName,
    String? toAccountName,
  }) {
    final amountStr = AmountFormatter.formatCompactCurrency(amount, locale);

    if (type.isTransferOut) {
      final dest = toWalletName ?? '?';
      final prefix = toAccountName != null ? '$toAccountName / ' : '';
      return (actorName: actorName, rest: ' chuyển $amountStr → $prefix$dest 💸');
    }
    if (type.isTransferIn) {
      final src = toWalletName ?? '?';
      final prefix = toAccountName != null ? '$toAccountName / ' : '';
      return (actorName: null, rest: 'Nhận $amountStr từ $prefix$src 💸');
    }

    final emoji = getCategoryEmoji(categoryName);
    final label = note != null && note.isNotEmpty ? note : categoryName.toLowerCase();
    return (actorName: actorName, rest: ' $label $amountStr $emoji');
  }
}
