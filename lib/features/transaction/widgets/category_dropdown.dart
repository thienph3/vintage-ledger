import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class CategoryDropdown extends StatelessWidget {
  final int? value;
  final List<Category> categories;
  final ValueChanged<int?> onChanged;
  final VoidCallback onAdd;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.categories,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: S.of(context, 'category'),
      ),
      items: [
        DropdownMenuItem(
          value: -1,
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 8),
              Text(S.of(context, 'addCategory'), style: AppTextStyles.body),
            ],
          ),
        ),
        ...categories.map((c) {
          return DropdownMenuItem(
            value: c.id,
            child: Row(
              children: [
                Icon(
                  getCategoryIcon(c.icon) ?? Icons.category,
                  size: 20,
                  color: AppColors.inkBlue,
                ),
                const SizedBox(width: 8),
                Text(c.name, style: AppTextStyles.body),
              ],
            ),
          );
        }),
      ],
      onChanged: (v) {
        if (v == -1) {
          onAdd();
          return;
        }
        onChanged(v);
      },
      validator: (v) {
        if (v == null || v == -1) {
          return S.of(context, 'selectCategoryRequired');
        }
        return null;
      },
    );
  }
}
