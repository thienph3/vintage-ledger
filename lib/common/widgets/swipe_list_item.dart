import 'package:flutter/material.dart';

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
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),

      confirmDismiss: (_) async {
        if (confirmDelete != null) {
          return await confirmDelete!();
        }
        return true;
      },

      onDismissed: (_) {
        if (onDelete != null) {
          onDelete!();
        }
      },

      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}