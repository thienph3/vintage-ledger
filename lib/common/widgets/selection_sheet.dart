import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class SelectionItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;

  const SelectionItem({required this.value, required this.label, this.icon, this.color});
}

Future<T?> showSelectionSheet<T>({
  required BuildContext context,
  required String title,
  required List<SelectionItem<T>> items,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(title, style: AppTextStyles.titleSmall),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: items.map((item) {
                final isSelected = item.value == selected;
                return ListTile(
                  leading: item.icon != null
                      ? Icon(item.icon, size: 20, color: item.color ?? AppColors.primary)
                      : null,
                  title: Text(item.label, style: AppTextStyles.body.copyWith(
                    color: item.color,
                  )),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.06) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg)),
                  onTap: () => Navigator.pop(ctx, item.value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}
