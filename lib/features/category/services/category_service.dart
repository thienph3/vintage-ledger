import 'package:vintage_ledger/core/constants/seed_categories.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repo = CategoryRepository();

  Stream<List<Category>> watchCategories() => _repo.watchCategories();

  Stream<List<Category>> watchByType(String type) => _repo.watchByType(type);

  Future<List<Category>> getCategories() async {
    return await _repo.getAll();
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    final all = await getCategories();
    return all.where((c) => c.type?.value == type).toList();
  }

  Future<Category?> getCategory(String id) async {
    final all = await getCategories();
    return all.where((c) => c.id == id).firstOrNull ?? await _repo.getById(id);
  }

  Future<String> createCategory(String name, {TransactionType? type, int? icon}) async {
    if (name.trim().isEmpty) throw Exception("Category name cannot be empty");
    return await _repo.add(Category(name: name, type: type, icon: icon));
  }

  Future<void> updateCategory(String id, String name, {TransactionType? type, int? icon}) async {
    await _repo.update(id, {'name': name, 'type': type?.value, 'icon': icon});
  }

  Future<void> deleteCategory(String id) async {
    final cat = await getCategory(id);
    if (cat != null && cat.isSystem) {
      throw Exception('Cannot delete system category');
    }
    await _repo.delete(id);
  }

  /// Look up a system category by its key (e.g. 'funding', 'transfer').
  /// Auto-creates it from seed data if it doesn't exist yet (for legacy accounts).
  Future<Category> ensureSystemCategory(String systemKey) async {
    final existing = await _repo.getBySystemKey(systemKey);
    if (existing != null) return existing;

    // Find seed definition
    final seed = kSeedCategories.where((s) => s.systemKey == systemKey).firstOrNull;
    if (seed == null) throw Exception('Unknown system category key: $systemKey');

    // Create it
    final id = await _repo.addSystem(
      name: seed.name,
      type: seed.type,
      icon: seed.iconCodePoint,
      systemKey: systemKey,
    );
    return Category(
      id: id,
      name: seed.name,
      type: seed.type,
      icon: seed.iconCodePoint,
      isSystem: true,
    );
  }
}
