import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle _titleBase = TextStyle(
    fontFamily: 'SpecialElite',
    fontSize: 24,
  );

  static const TextStyle _bodyBase = TextStyle(
    fontFamily: 'PatrickHand',
    fontSize: 18,
  );

  static const TextStyle _amountBase = TextStyle(
    fontFamily: 'SpecialElite',
    fontSize: 18,
  );

  // Public styles
  static TextStyle title = _titleBase.copyWith(
    color: AppColors.inkPurple,
  );

  static TextStyle body = _bodyBase.copyWith(
    color: AppColors.inkBlue,
  );

  static TextStyle amount = _amountBase.copyWith(
    color: AppColors.inkBlue,
  );
}