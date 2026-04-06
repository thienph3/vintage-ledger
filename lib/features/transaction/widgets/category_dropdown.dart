import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
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
    final selected = categories.where((c) => c.id == value).firstOrNull;

    return FormField<String>(
      initialValue: value,
      validator: (v) => v == null && value == null ? S.of(context, 'selectCategoryRequired') : null,
      builder: (state) {
        return GestureDetector(
          onTap: () => _showPicker(context, state),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: S.of(context, 'category'),
              prefixIcon: Icon(
                getCategoryIcon(selected?.icon),
                size: 20,
                color: AppColors.primary,
              ),
              suffixIcon: const Icon(Icons.unfold_more, size: 18),
              errorText: state.errorText,
            ),
            child: Text(
              selected?.name ?? '',
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPicker(BuildContext context, FormFieldState<String> state) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(S.of(context, 'category'), style: AppTextStyles.titleSmall),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Add category option
                  ListTile(
                    leading: const Icon(Icons.add, size: 20),
                    title: Text(S.of(context, 'addCategory'), style: AppTextStyles.body),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onTap: () {
                      Navigator.pop(ctx);
                      onAdd();
                    },
                  ),
                  ...categories.map((c) {
                    final isSelected = c.id == value;
                    return ListTile(
                      leading: Icon(getCategoryIcon(c.icon), size: 20, color: AppColors.primary),
                      title: Text(c.name, style: AppTextStyles.body),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                      tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.06) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onTap: () => Navigator.pop(ctx, c.id),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (result != null) {
      onChanged(result);
      state.didChange(result);
    }
  }
}
