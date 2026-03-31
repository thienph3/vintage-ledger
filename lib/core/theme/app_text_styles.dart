import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';

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

  // Titles
  static final TextStyle title = _titleBase.copyWith(color: AppColors.inkPurple);
  static final TextStyle titleSmall = _titleBase.copyWith(color: AppColors.inkPurple, fontSize: 16);

  // Body
  static final TextStyle body = _bodyBase.copyWith(color: AppColors.inkBlue);
  static final TextStyle bodyBold = _bodyBase.copyWith(color: AppColors.inkBlue, fontWeight: FontWeight.bold);
  static final TextStyle bodySmall = _bodyBase.copyWith(color: AppColors.inkBlue, fontSize: 14);

  // Amount
  static final TextStyle amount = _amountBase.copyWith(color: AppColors.inkBlue);

  // Headline (lock screen, large titles)
  static final TextStyle headline = _titleBase.copyWith(color: AppColors.inkBlack, fontSize: 20, fontWeight: FontWeight.bold);

  // Link / action text
  static final TextStyle link = _bodyBase.copyWith(color: AppColors.inkBlack, fontSize: 14, fontWeight: FontWeight.bold);

  // Caption (chart axis labels, small info)
  static const TextStyle caption = TextStyle(fontSize: 10, color: AppColors.inkBlack);

  // Hint / empty state
  static final TextStyle hint = _bodyBase.copyWith(color: Colors.grey, fontSize: 16);

  // Error
  static final TextStyle error = _bodyBase.copyWith(color: AppColors.expense);

  // Button label
  static final TextStyle buttonLabel = _titleBase.copyWith(fontSize: 18, fontWeight: FontWeight.bold);

  // Keypad
  static const TextStyle keypad = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.inkBlack);

  // Emoji / flag
  static const TextStyle emoji = TextStyle(fontSize: 24);
  static const TextStyle emojiLarge = TextStyle(fontSize: 28);

  // Column header
  static final TextStyle columnHeader = _bodyBase.copyWith(color: AppColors.inkBlack, fontWeight: FontWeight.bold);
}
