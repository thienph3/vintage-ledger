import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';

class SwipeListItem extends StatelessWidget {
  final Key itemKey;
  final Widget child;
  final VoidCallback? onTap;
  final Future<bool?> Function()? confirmDelete;
  final VoidCallback? onDelete;

  const SwipeListItem({
    super.key,
    required this.itemKey,
    required this.child,
    this.onTap,
    this.confirmDelete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction: onDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        if (confirmDelete != null) return await confirmDelete!();
        return true;
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}
