import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repo = CategoryRepository();

  /// CREATE CATEGORY
  Future<int> createCategory(String name, {int? icon}) async {
    if (name.trim().isEmpty) {
      throw Exception("Category name cannot be empty");
    }

    final category = Category(
      name: name,
      icon: icon, // thêm icon
    );

    return await _repo.create(category);
  }

  /// GET ALL CATEGORIES
  Future<List<Category>> getCategories() async {
    return await _repo.getAll();
  }

  /// GET CATEGORY BY ID
  Future<Category?> getCategory(int id) async {
    return await _repo.getById(id);
  }

  /// UPDATE CATEGORY
  Future<int> updateCategory(int id, String name, {int? icon}) async {
    final category = await _repo.getById(id);

    if (category == null) {
      throw Exception("Category not found");
    }

    final updated = Category(
      id: id,
      name: name,
      icon: icon, // cập nhật icon
    );

    return await _repo.update(updated);
  }

  /// DELETE CATEGORY
  Future<int> deleteCategory(int id) async {
    return await _repo.delete(id);
  }
}