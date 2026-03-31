import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/l10n/s.dart';

Future<bool?> showDeleteConfirmation(
  BuildContext context, {
  required String titleKey,
  required String contentKey,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(S.of(ctx, titleKey)),
      content: Text(S.of(ctx, contentKey)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(S.of(ctx, 'cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(S.of(ctx, 'delete')),
        ),
      ],
    ),
  );
}
