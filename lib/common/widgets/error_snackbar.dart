import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/error_mapper.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';

void showErrorSnackBar(BuildContext context, Object error, {VoidCallback? onRetry}) {
  if (!context.mounted) return;

  final mapped = ErrorMapper.map(error);
  final message = S.of(context, mapped.message);

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: AppColors.error,
    action: SnackBarAction(
      label: onRetry != null ? S.of(context, 'retry') : S.of(context, 'dismiss'),
      textColor: Colors.white,
      onPressed: onRetry ?? () {},
    ),
  ));
}
