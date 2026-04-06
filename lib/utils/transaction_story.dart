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
    String? toAccountName,
  }) {
    final amountStr = AmountFormatter.formatCompactCurrency(amount, locale);

    if (type.isTransferOut) {
      final dest = toWalletName ?? '?';
      final prefix = toAccountName != null ? '$toAccountName / ' : '';
      return '$actorName chuyển $amountStr → $prefix$dest 💸';
    }
    if (type.isTransferIn) {
      final src = toWalletName ?? '?';
      final prefix = toAccountName != null ? '$toAccountName / ' : '';
      return 'Nhận $amountStr từ $prefix$src 💸';
    }

    final emoji = getCategoryEmoji(categoryName);
    final label = note != null && note.isNotEmpty ? note : categoryName.toLowerCase();
    return '$actorName $label $amountStr $emoji';
  }
}
