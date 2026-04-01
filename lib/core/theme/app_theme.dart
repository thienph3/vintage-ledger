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
      error: AppColors.expense,
    ),

    // TEXT THEME
    textTheme: TextTheme(
      headlineSmall: AppTextStyles.headline,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.title.copyWith(fontSize: 20),
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.body.copyWith(fontSize: 20),
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.buttonLabel,
      labelSmall: AppTextStyles.caption,
    ),

    // APPBAR
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.title.copyWith(fontSize: 22),
      iconTheme: const IconThemeData(color: AppColors.inkBlue),
    ),

    // ICON
    iconTheme: const IconThemeData(color: AppColors.inkBlue),

    // DIVIDER
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1.2,
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
      floatingLabelBehavior: FloatingLabelBehavior.always,
      hintStyle: AppTextStyles.hint,
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.inkPurple),
    ),

    // ELEVATED BUTTON
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.inkBlue,
        foregroundColor: Colors.white,
        textStyle: AppTextStyles.buttonLabel,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),

    // TEXT BUTTON
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.inkPurple,
        textStyle: AppTextStyles.body,
      ),
    ),

    // OUTLINED BUTTON
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkBlue,
        side: const BorderSide(color: AppColors.inkBlue),
        textStyle: AppTextStyles.body,
      ),
    ),

    // TAB BAR
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.inkBlue,
      unselectedLabelColor: Colors.grey,
      labelStyle: AppTextStyles.body,
      unselectedLabelStyle: AppTextStyles.body,
      indicatorColor: AppColors.inkBlue,
    ),

    // LIST TILE
    listTileTheme: ListTileThemeData(
      titleTextStyle: AppTextStyles.body,
      subtitleTextStyle: AppTextStyles.bodySmall,
      iconColor: AppColors.inkBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
      showCloseIcon: true,
      closeIconColor: Colors.white,
    ),

    // BOTTOM SHEET
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // CHECKBOX
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => AppColors.inkBlue),
    ),

    // SWITCH
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => AppColors.inkBlue),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.inkBlue.withValues(alpha: 0.4),
      ),
    ),

    // PROGRESS
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.inkBlue,
    ),

    // RADIO
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) => AppColors.inkBlue),
    ),

    // DROPDOWN
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.paper),
      ),
    ),
  );
}
