import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/ledger_list_tile.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/error_snackbar.dart';
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
  List<Category> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await sl.categoryService.getCategories();
    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'categories'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  if (_items.isEmpty)
                    EmptyState(message: S.of(context, 'noCategories')),
                  ..._items.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SwipeListItem(
                      itemKey: Key(c.id!),
                      onTap: () async {
                        await context.pushScreen(CategoryFormScreen(category: c));
                        _load();
                      },
                      confirmDelete: () => showDeleteConfirmation(context, titleKey: 'deleteCategory', contentKey: 'deleteCategoryConfirm'),
                      onDelete: () async {
                        try {
                          await sl.categoryService.deleteCategory(c.id!);
                          _load();
                        } catch (e) {
                          if (!context.mounted) return;
                          showErrorSnackBar(context, e);
                        }
                      },
                      child: LedgerListTile(
                        child: Row(
                          children: [
                            Icon(getCategoryIcon(c.icon), size: 28, color: AppColors.inkBlue),
                            const SizedBox(width: 16),
                            Expanded(child: Text(c.name, style: AppTextStyles.bodyBold)),
                          ],
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await context.pushScreen(const CategoryFormScreen());
                        _load();
                      },
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
