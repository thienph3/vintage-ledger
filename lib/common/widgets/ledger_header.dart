import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class LedgerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const LedgerHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.2),
        child: Divider(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.2);
}
