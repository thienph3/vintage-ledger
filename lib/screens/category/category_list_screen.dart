import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/ledger_header.dart';
import '../../widgets/swipe_list_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService categoryService = CategoryService();
  List<Category> categories = [];

  /// Map các index sang IconData constant
  final Map<int, IconData> iconMap = {
    0: Icons.fastfood,
    1: Icons.directions_car,
    2: Icons.shopping_cart,
    3: Icons.home,
    4: Icons.sports_soccer,
    5: Icons.movie,
    6: Icons.local_cafe,
    7: Icons.health_and_safety,
    8: Icons.phone_iphone,
    9: Icons.school,
    10: Icons.pets,
    11: Icons.flight,
    12: Icons.music_note,
    13: Icons.local_hospital,
  };

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final list = await categoryService.getCategories();
    setState(() => categories = list);
  }

  Future<void> deleteCategory(int id) async {
    await categoryService.deleteCategory(id);
    loadCategories();
  }

  Future<bool?> confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa danh mục"),
        content: const Text("Bạn có chắc chắn muốn xóa danh mục này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );
  }

  Future<void> openForm({Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
    if (result == true) loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "",
      body: RefreshIndicator(
        onRefresh: loadCategories,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const LedgerHeader(
              title: "DANH MỤC",
              showBackButton: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (categories.isEmpty)
              const Center(child: Text("Chưa có danh mục nào")),
            ...categories.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SwipeListItem(
                    itemKey: Key(c.id.toString()),
                    onTap: () => openForm(category: c),
                    confirmDelete: confirmDelete,
                    onDelete: () => deleteCategory(c.id!),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            // Dùng map để lấy IconData constant, nếu index hợp lệ
                            (c.icon != null && iconMap.containsKey(c.icon))
                                ? iconMap[c.icon]!
                                : Icons.category,
                            size: 28,
                            color: AppColors.inkBlue,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              c.name,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => openForm(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  "Thêm danh mục",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: AppColors.inkBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}