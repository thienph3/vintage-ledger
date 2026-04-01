import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/category/models/category.dart';

class CategoryDropdown extends StatelessWidget {
  final String? value;
  final List<Category> categories;
  final ValueChanged<String?> onChanged;
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
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: S.of(context, 'category')),
      items: [
        DropdownMenuItem(
          value: '__add__',
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 8),
              Text(S.of(context, 'addCategory'), style: AppTextStyles.body),
            ],
          ),
        ),
        ...categories.map((c) => DropdownMenuItem(
          value: c.id,
          child: Row(
            children: [
              Icon(getCategoryIcon(c.icon), size: 20, color: AppColors.inkBlue),
              const SizedBox(width: 8),
              Text(c.name, style: AppTextStyles.body),
            ],
          ),
        )),
      ],
      onChanged: (v) {
        if (v == '__add__') { onAdd(); return; }
        onChanged(v);
      },
      validator: (v) => v == null || v == '__add__' ? S.of(context, 'selectCategoryRequired') : null,
    );
  }
}
