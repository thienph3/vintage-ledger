import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/ledger_header.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final CategoryService categoryService = CategoryService();
  List<Category> categories = [];

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
        title: Text(S.of(context, 'deleteCategory')),
        content: Text(S.of(context, 'deleteCategoryConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.of(context, 'cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(S.of(context, 'delete'))),
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
            LedgerHeader(
              title: S.of(context, 'categories'),
              showBackButton: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (categories.isEmpty)
              Center(child: Text(S.of(context, 'noCategories'))),
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
                            (c.icon != null && kCategoryIconMap.containsKey(c.icon))
                                ? kCategoryIconMap[c.icon]!
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
                label: Text(
                  S.of(context, 'addCategory'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
