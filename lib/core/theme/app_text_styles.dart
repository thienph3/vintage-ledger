import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';

class AppTextStyles {
  // Titles — weight 600
  static const TextStyle title = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Body — weight 400
  static const TextStyle body = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Amount — clear, aligned
  static const TextStyle amount = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Hint / empty state
  static const TextStyle hint = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  // Error
  static const TextStyle error = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.expense,
  );

  // Button
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
  );

  // Link
  static const TextStyle link = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary,
  );

  // Keypad
  static const TextStyle keypad = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Column header
  static const TextStyle columnHeader = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // Emoji
  static const TextStyle emoji = TextStyle(fontSize: 24);
  static const TextStyle emojiLarge = TextStyle(fontSize: 28);
}
