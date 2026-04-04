import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class SelectionItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SelectionItem({required this.value, required this.label, this.icon});
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
                      ? Icon(item.icon, size: 20, color: AppColors.primary)
                      : null,
                  title: Text(item.label, style: AppTextStyles.body),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.06) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
