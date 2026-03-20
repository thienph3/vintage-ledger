import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class LedgerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const LedgerHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Divider vintage
        Divider(color: AppColors.divider, thickness: 1.2),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56 + 1.2);
}
