import 'package:vintage_ledger/core/firestore/firestore_repository.dart';
import 'package:vintage_ledger/features/budget/models/budget.dart';

class BudgetRepository extends FirestoreRepository<Budget> {
  @override
  String get collectionName => 'budgets';

  @override
  Budget fromFirestore(String id, Map<String, dynamic> data) => Budget(
    id: id,
    categoryId: data['category_id'] ?? '',
    amountLimit: data['amount_limit'] ?? 0,
    period: data['period'] ?? 'monthly',
  );

  @override
  Map<String, dynamic> toFirestore(Budget item) => {
    'category_id': item.categoryId,
    'amount_limit': item.amountLimit,
    'period': item.period,
  };

  Stream<List<Budget>> watchBudgets() => watchAll();

  Future<Budget?> getByCategoryId(String categoryId) async {
    final all = await getAll(
      queryBuilder: (ref) => ref.where('category_id', isEqualTo: categoryId).limit(1),
    );
    return all.firstOrNull;
  }
}
