import 'transaction.dart';
import 'transaction_item.dart';

class TransactionWithItems {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;

  TransactionWithItems({
    required this.transaction,
    this.items = const [],
  });

  int get remainingAmount {
    final totalItems = items.fold(0, (sum, item) => sum + item.amount);
    return transaction.amount - totalItems;
  }
}
