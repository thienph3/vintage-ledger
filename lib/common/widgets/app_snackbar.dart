import 'package:flutter/material.dart';

const _kDuration = Duration(seconds: 3);

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Color? backgroundColor,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    duration: _kDuration,
    action: action,
    backgroundColor: backgroundColor,
    persist: false,
  ));
}
