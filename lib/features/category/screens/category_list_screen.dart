import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/empty_state.dart';
import 'package:vintage_ledger/common/widgets/swipe_list_item.dart';
import 'package:vintage_ledger/common/widgets/delete_confirmation.dart';
import 'package:vintage_ledger/common/widgets/app_snackbar.dart';
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
    final items = sl.cache.categories;
    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  List<Category> get _expenseCategories =>
      _items.where((c) => c.type == TransactionType.expense).toList();

  List<Category> get _incomeCategories =>
      _items.where((c) => c.type == TransactionType.income).toList();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'categories'),
      body: _loading
          ? const ShimmerPlaceholder()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (_items.isEmpty)
                    EmptyState(message: S.of(context, 'noCategories')),

                  // Expense section
                  if (_expenseCategories.isNotEmpty) ...[
                    _buildSectionHeader(
                      S.of(context, 'expense'),
                      Icons.arrow_upward,
                      AppColors.expense,
                    ),
                    ..._expenseCategories.map(_buildCategoryTile),
                  ],

                  // Income section
                  if (_incomeCategories.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildSectionHeader(
                      S.of(context, 'income'),
                      Icons.arrow_downward,
                      AppColors.income,
                    ),
                    ..._incomeCategories.map(_buildCategoryTile),
                  ],

                  const SizedBox(height: AppSpacing.lg),
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

  Widget _buildSectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.titleSmall.copyWith(color: color)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Category c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwipeListItem(
        itemKey: Key(c.id!),
        onTap: () async {
          await context.pushScreen(CategoryFormScreen(category: c));
          _load();
        },
        confirmDelete: () => showDeleteConfirmation(
          context, titleKey: 'deleteCategory', contentKey: 'deleteCategoryConfirm',
        ),
        onDelete: () async {
          try {
            await sl.categoryService.deleteCategory(c.id!);
            _load();
          } catch (e) {
            if (!context.mounted) return;
            showAppSnackBar(context, e.toString(), backgroundColor: AppColors.error);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md2),
          child: Row(
            children: [
              Icon(getCategoryIcon(c.icon), size: 28, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(c.name, style: AppTextStyles.bodyBold)),
            ],
          ),
        ),
      ),
    );
  }
}
