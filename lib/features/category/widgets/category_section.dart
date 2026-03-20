import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

import 'package:vintage_ledger/common/widgets/empty_state.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class CategorySection extends StatelessWidget {
  final List<Category> categories;
  final Function() onAddCategory;
  final Function(Category) onTapCategory;
  final Function(Category) onDeleteCategory;

  const CategorySection({
    super.key,
    required this.categories,
    required this.onAddCategory,
    required this.onTapCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              S.of(context, 'category'),
              style: AppTextStyles.title,
            ),

            InkWell(
              onTap: onAddCategory,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    S.of(context, 'addCategory'),
                    style: const TextStyle(
                      color: AppColors.inkBlack,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            Expanded(
              child: Text(S.of(context, 'categoryNameColumn')),
            ),
          ],
        ),

        Divider(color: AppColors.divider, thickness: 1.2),

        if (categories.isEmpty)
          EmptyState(message: S.of(context, 'noCategoriesFound')),

        if (categories.isNotEmpty)
          ...categories.map((category) {

            return InkWell(

              onTap: () => onTapCategory(category),

              onLongPress: () async {

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(S.of(context, 'deleteCategory')),
                    content: Text(
                      S.of(context, 'deleteCategoryConfirm'),
                    ),
                    actions: [

                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.of(context, 'cancel')),
                      ),

                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(S.of(context, 'delete')),
                      ),

                    ],
                  ),
                );

                if (confirm == true) {
                  onDeleteCategory(category);
                }
              },

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [

                    Expanded(
                      child: Text(
                        category.name,
                        style: AppTextStyles.body,
                      ),
                    ),

                  ],
                ),
              ),
            );

          }),

      ],
    );
  }
}
