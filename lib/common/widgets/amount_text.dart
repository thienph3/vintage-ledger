import 'package:flutter/material.dart';

import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/utils/amount_formatter.dart';

class AmountText extends StatelessWidget {

  final int amount;
  final String type;
  final double? fontSize;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.fontSize,
  });

  String formatAmountCompact(int value) {
    if (value >= 1000000000 && value % 100000000 == 0) {
      final result = value / 1000000000;
      return result % 1 == 0
          ? "${result.toInt()}b"
          : "${result.toStringAsFixed(1)}b";
    }
    if (value >= 1000000 && value % 100000 == 0) {
      final result = value / 1000000;
      return result % 1 == 0
          ? "${result.toInt()}m"
          : "${result.toStringAsFixed(1)}m";
    }
    if (value >= 1000 && value % 100 == 0) {
      final result = value / 1000;
      return result % 1 == 0
          ? "${result.toInt()}k"
          : "${result.toStringAsFixed(1)}k";
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {

    final color =
        type == "income" ? AppColors.income : AppColors.expense;

    final sign =
        type == "income" ? "" : "-";

    final formatted = AmountFormatter.formatCurrency(amount);

    return Text(
      "$sign$formatted",
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? 16,
      ),
    );
  }
}