import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class LedgerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onTitleTap;

  const LedgerHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(title, style: AppTextStyles.title);

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: onTitleTap != null
          ? GestureDetector(
              onTap: onTitleTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: titleWidget),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14),
                ],
              ),
            )
          : titleWidget,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
