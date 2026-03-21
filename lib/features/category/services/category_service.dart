import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repo = CategoryRepository();

  Future<int> createCategory(String name, {String? type, int? icon}) async {
    if (name.trim().isEmpty) {
      throw Exception("Category name cannot be empty");
    }
    return await _repo.create(Category(name: name, type: type, icon: icon));
  }

  Future<List<Category>> getCategories() async {
    return await _repo.getAll();
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    return await _repo.getByType(type);
  }

  Future<Category?> getCategory(int id) async {
    return await _repo.getById(id);
  }

  Future<int> updateCategory(int id, String name,
      {String? type, int? icon}) async {
    final category = await _repo.getById(id);
    if (category == null) throw Exception("Category not found");
    return await _repo.update(
        Category(id: id, name: name, type: type, icon: icon));
  }

  Future<int> deleteCategory(int id) async {
    return await _repo.delete(id);
  }
}
