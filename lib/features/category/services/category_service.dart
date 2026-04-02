import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repo = CategoryRepository();

  List<Category>? _cache;

  Stream<List<Category>> watchCategories() => _repo.watchCategories();

  Stream<List<Category>> watchByType(String type) => _repo.watchByType(type);

  Future<List<Category>> getCategories() async {
    if (_cache != null) return _cache!;
    // Try local cache first for instant load
    try {
      _cache = await _repo.getAll(useCache: true);
      if (_cache!.isNotEmpty) {
        // Background refresh from server
        _repo.getAll().then((fresh) => _cache = fresh);
        return _cache!;
      }
    } catch (_) {}
    _cache = await _repo.getAll();
    return _cache!;
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
    final id = await _repo.add(Category(name: name, type: type, icon: icon));
    _cache = null;
    return id;
  }

  Future<void> updateCategory(String id, String name, {TransactionType? type, int? icon}) async {
    await _repo.update(id, {'name': name, 'type': type?.value, 'icon': icon});
    _cache = null;
  }

  Future<void> deleteCategory(String id) async {
    await _repo.delete(id);
    _cache = null;
  }
}
