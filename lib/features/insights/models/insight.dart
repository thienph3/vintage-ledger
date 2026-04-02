import 'package:flutter/material.dart';

enum InsightType { topCategory, weeklyChange, savings }

class Insight {
  final InsightType type;
  final String message;
  final IconData icon;
  final Color color;

  const Insight({
    required this.type,
    required this.message,
    required this.icon,
    required this.color,
  });
}
