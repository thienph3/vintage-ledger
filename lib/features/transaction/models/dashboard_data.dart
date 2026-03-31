import 'package:vintage_ledger/features/transaction/models/transaction_with_items.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class DashboardData {
  final List<TransactionWithItems> recent;
  final List<TransactionWithItems> monthly;
  final Map<int, Category> categoryMap;
  final int balance;

  const DashboardData({
    required this.recent,
    required this.monthly,
    required this.categoryMap,
    required this.balance,
  });
}
