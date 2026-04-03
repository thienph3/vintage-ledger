import 'package:vintage_ledger/core/constants/category_emojis.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class TransactionStory {
  /// Format: "Minh ăn trưa 80k 🍜" or "Bạn cafe 30k ☕"
  static String format({
    required String actorName,
    required String categoryName,
    required int amount,
    required TransactionType type,
    required String locale,
    String? note,
  }) {
    final emoji = getCategoryEmoji(categoryName);
    final amountStr = AmountFormatter.formatCompactCurrency(amount, locale);
    final label = note != null && note.isNotEmpty ? note : categoryName.toLowerCase();

    return '$actorName $label $amountStr $emoji';
  }
}
