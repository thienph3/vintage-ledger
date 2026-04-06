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
  }) {
    final amountStr = AmountFormatter.formatCompactCurrency(amount, locale);

    if (type.isTransfer || type.isTransferOut) {
      return '$actorName chuyển $amountStr 💸';
    }
    if (type.isTransferIn) {
      return 'Nhận $amountStr 💸';
    }

    final emoji = getCategoryEmoji(categoryName);
    final label = note != null && note.isNotEmpty ? note : categoryName.toLowerCase();
    return '$actorName $label $amountStr $emoji';
  }
}
