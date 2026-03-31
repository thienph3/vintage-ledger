import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/ledger_list_tile.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/utils/navigator_x.dart';

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

  Future<void> openForm({Category? category}) async {
    final result = await context.pushScreen(CategoryFormScreen(category: category));
    if (result == true) loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'categories'),
      body: RefreshIndicator(
        onRefresh: loadCategories,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: AppSpacing.sm),
            if (categories.isEmpty)
              EmptyState(message: S.of(context, 'noCategories')),
            ...categories.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SwipeListItem(
                  itemKey: Key(c.id.toString()),
                  onTap: () => openForm(category: c),
                  confirmDelete: () => showDeleteConfirmation(
                    context,
                    titleKey: 'deleteCategory',
                    contentKey: 'deleteCategoryConfirm',
                  ),
                  onDelete: () => deleteCategory(c.id!),
                  child: LedgerListTile(
                    child: Row(
                      children: [
                        Icon(
                          getCategoryIcon(c.icon),
                          size: 28,
                          color: AppColors.inkBlue,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(c.name, style: AppTextStyles.bodyBold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => openForm(),
                icon: const Icon(Icons.add, size: 16),
                label: Text(S.of(context, 'addCategory')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
