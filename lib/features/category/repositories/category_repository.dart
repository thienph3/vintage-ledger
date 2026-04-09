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
    isSystem: data['is_system'] == true,
  );

  @override
  Map<String, dynamic> toFirestore(Category item) => {
    'name': item.name,
    'type': item.type?.value,
    'icon': item.icon,
    if (item.isSystem) 'is_system': true,
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

  Future<Category?> getBySystemKey(String key) async {
    final snap = await collection
        .where('system_key', isEqualTo: key)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return fromFirestore(doc.id, doc.data());
  }

  Future<String> addSystem({
    required String name,
    required TransactionType type,
    required int icon,
    required String systemKey,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final doc = await collection.add({
      'name': name,
      'type': type.value,
      'icon': icon,
      'is_system': true,
      'system_key': systemKey,
      'created_at': now,
      'updated_at': now,
    });
    return doc.id;
  }
}
