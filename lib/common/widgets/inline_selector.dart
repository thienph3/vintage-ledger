import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class InlineSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const InlineSelector({
    super.key,
    required this.icon,
    required this.label,
    this.isPlaceholder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPlaceholder ? AppColors.expense : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: isPlaceholder ? AppColors.expense : null),
          ),
          Icon(Icons.unfold_more, size: 10, color: color),
        ],
      ),
    );
  }
}
