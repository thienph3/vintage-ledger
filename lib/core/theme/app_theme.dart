import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'PatrickHand',
    scaffoldBackgroundColor: AppColors.paper,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.inkBlue,
      brightness: Brightness.light,
    ),

    // TEXT THEME
    textTheme: TextTheme(
      bodyMedium: AppTextStyles.body,
      bodyLarge: AppTextStyles.body.copyWith(fontSize: 20),
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.title.copyWith(fontSize: 20),
    ),

    // APPBAR
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.title.copyWith(fontSize: 22),
      iconTheme: const IconThemeData(color: AppColors.inkBlue),
    ),

    // INPUT
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inkBlue, width: 2),
      ),
      hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.inkPurple),
    ),

    // BUTTONS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => AppColors.inkBlue,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => Colors.white,
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.title.copyWith(fontSize: 18),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.inkPurple,
        textStyle: AppTextStyles.body,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkBlue,
        side: const BorderSide(color: AppColors.inkBlue),
        textStyle: AppTextStyles.body,
      ),
    ),

    // DIALOG
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: AppTextStyles.title.copyWith(fontSize: 20),
      contentTextStyle: AppTextStyles.body.copyWith(fontSize: 16),
    ),

    // SNACKBAR
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inkBlue,
      contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),

    // CHECKBOX
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => AppColors.inkBlue),
    ),

    // SWITCH
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.inkBlue,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.inkBlue.withValues(alpha: 0.4),
      ),
    ),

    // PROGRESS
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.inkBlue,
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => AppColors.inkBlue),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.paper),
      ),
    ),
  );
}
