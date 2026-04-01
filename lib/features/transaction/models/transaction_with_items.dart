import 'package:vintage_ledger/features/transaction/models/transaction.dart';
import 'package:vintage_ledger/features/transaction/models/transaction_item.dart';

class TransactionWithItems {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;

  TransactionWithItems({required this.transaction, this.items = const []});

  int get remainingAmount {
    final totalItems = items.fold(0, (sum, item) => sum + item.amount);
    return transaction.amount - totalItems;
  }
}
