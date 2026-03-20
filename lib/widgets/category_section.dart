import 'package:flutter/material.dart';

import '../models/category.dart';

import '../widgets/empty_state.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

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

        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              "Danh mục",
              style: AppTextStyles.title,
            ),

            InkWell(
              onTap: onAddCategory,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Thêm",
                    style: TextStyle(
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

        /// TABLE HEADER
        const Row(
          children: [
            Expanded(
              child: Text("Tên danh mục"),
            ),
          ],
        ),

        Divider(color: AppColors.divider, thickness: 1.2),

        /// EMPTY
        if (categories.isEmpty)
          const EmptyState(message: "Không có danh mục nào"),

        /// LIST
        if (categories.isNotEmpty)
          ...categories.map((category) {

            return InkWell(

              onTap: () => onTapCategory(category),

              onLongPress: () async {

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Xóa danh mục"),
                    content: const Text(
                      "Bạn có chắc muốn xóa danh mục này?",
                    ),
                    actions: [

                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Hủy"),
                      ),

                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Xóa"),
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