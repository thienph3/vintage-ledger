import 'package:vintage_ledger/core/firestore/firestore_repository.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class CategoryRepository extends FirestoreRepository<Category> {
  @override
  String get collectionName => 'categories';

  @override
  Category fromFirestore(String id, Map<String, dynamic> data) => Category(
    id: id,
    name: data['name'] ?? '',
    type: data['type'] != null ? TransactionType.fromString(data['type']) : null,
    icon: data['icon'],
  );

  @override
  Map<String, dynamic> toFirestore(Category item) => {
    'name': item.name,
    'type': item.type?.value,
    'icon': item.icon,
  };

  Stream<List<Category>> watchCategories() => watchAll(
    queryBuilder: (ref) => ref.orderBy('name'),
  );

  Stream<List<Category>> watchByType(String type) => watchAll(
    queryBuilder: (ref) => ref.where('type', isEqualTo: type).orderBy('name'),
  );

  Future<List<Category>> getByType(String type) => getAll(
    queryBuilder: (ref) => ref.where('type', isEqualTo: type).orderBy('name'),
  );
}
