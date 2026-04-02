import 'package:flutter/material.dart';

class CoachingTip {
  final String dismissKey;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? action;

  const CoachingTip({
    required this.dismissKey,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.action,
  });
}
