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

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDeleteConfirmation(
      context,
      titleKey: 'deleteCategory',
      contentKey: 'deleteCategoryConfirm',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'categories'),
      body: StreamBuilder<List<Category>>(
        stream: sl.categoryService.watchCategories(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.sm),
              if (items.isEmpty)
                EmptyState(message: S.of(context, 'noCategories')),
              ...items.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SwipeListItem(
                  itemKey: Key(c.id!),
                  onTap: () => context.pushScreen(CategoryFormScreen(category: c)),
                  confirmDelete: () => _confirmDelete(context),
                  onDelete: () async {
                    try {
                      await sl.categoryService.deleteCategory(c.id!);
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
                  onPressed: () => context.pushScreen(const CategoryFormScreen()),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(S.of(context, 'addCategory')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
