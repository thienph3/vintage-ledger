import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repo = CategoryRepository();

  Stream<List<Category>> watchCategories() => _repo.watchCategories();

  Stream<List<Category>> watchByType(String type) => _repo.watchByType(type);

  Future<List<Category>> getCategories() => _repo.getAll();

  Future<List<Category>> getCategoriesByType(String type) => _repo.getByType(type);

  Future<Category?> getCategory(String id) => _repo.getById(id);

  Future<String> createCategory(String name, {TransactionType? type, int? icon}) async {
    if (name.trim().isEmpty) throw Exception("Category name cannot be empty");
    return await _repo.add(Category(name: name, type: type, icon: icon));
  }

  Future<void> updateCategory(String id, String name, {TransactionType? type, int? icon}) async {
    await _repo.update(id, {'name': name, 'type': type?.value, 'icon': icon});
  }

  Future<void> deleteCategory(String id) async {
    await _repo.delete(id);
  }
}
