import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';

void showErrorSnackBar(BuildContext context, Object error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('${S.of(context, 'error')}: $error'),
    backgroundColor: AppColors.inkRed,
    action: SnackBarAction(
      label: S.of(context, 'dismiss'),
      textColor: Colors.white,
      onPressed: () {},
    ),
  ));
}
