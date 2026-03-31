import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/repositories/category_repository.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class CategoryService {
  final CategoryRepository _repo = CategoryRepository();

  String get _accountId => sl.appState.currentAccountId;

  Future<int> createCategory(String name, {TransactionType? type, int? icon}) async {
    if (name.trim().isEmpty) throw Exception("Category name cannot be empty");
    return await _repo.create(Category(name: name, type: type, icon: icon, accountId: _accountId));
  }

  Future<List<Category>> getCategories() async {
    return await _repo.getAll(accountId: _accountId);
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    return await _repo.getByType(type, accountId: _accountId);
  }

  Future<Category?> getCategory(int id) async {
    return await _repo.getById(id);
  }

  Future<int> updateCategory(int id, String name,
      {TransactionType? type, int? icon}) async {
    final category = await _repo.getById(id);
    if (category == null) throw Exception("Category not found");
    return await _repo.update(
        Category(id: id, name: name, type: type, icon: icon, accountId: category.accountId));
  }

  Future<int> deleteCategory(int id) async {
    return await _repo.delete(id);
  }
}
