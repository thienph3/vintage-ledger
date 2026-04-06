import 'package:vintage_ledger/core/constants/category_emojis.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

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
  }) {
    final amountStr = AmountFormatter.formatCompactCurrency(amount, locale);

    if (type.isTransferOut) {
      final dest = toWalletName ?? '?';
      return '$actorName chuyển $amountStr → $dest 💸';
    }
    if (type.isTransferIn) {
      final src = toWalletName ?? '?';
      return 'Nhận $amountStr từ $src 💸';
    }

    final emoji = getCategoryEmoji(categoryName);
    final label = note != null && note.isNotEmpty ? note : categoryName.toLowerCase();
    return '$actorName $label $amountStr $emoji';
  }
}
