import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/common/mixins/crud_list_mixin.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/ledger_list_tile.dart';
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

class _CategoryListScreenState extends State<CategoryListScreen>
    with CrudListMixin<Category> {
  @override
  String get deleteTitle => 'deleteCategory';
  @override
  String get deleteContent => 'deleteCategoryConfirm';

  @override
  Future<List<Category>> fetchItems() => sl.categoryService.getCategories();
  @override
  Future<void> removeItem(Category item) => sl.categoryService.deleteCategory(item.id!);
  @override
  int itemId(Category item) => item.id!;
  @override
  Widget formScreen({Category? item}) => CategoryFormScreen(category: item);

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'categories'),
      body: RefreshIndicator(
        onRefresh: loadItems,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              EmptyState(message: S.of(context, 'noCategories')),
            ...items.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SwipeListItem(
                itemKey: Key(c.id.toString()),
                onTap: () => openForm(item: c),
                confirmDelete: confirmDelete,
                onDelete: () => deleteItem(c),
                child: LedgerListTile(
                  child: Row(
                    children: [
                      Icon(getCategoryIcon(c.icon),
                          size: 28, color: AppColors.inkBlue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(c.name, style: AppTextStyles.bodyBold),
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
                label: Text(S.of(context, 'addCategory')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
