import 'package:flutter/material.dart';

class AppColors {
  // Base
  static const background = Color(0xFFF8F8F6);
  static const surface = Color(0xFFFFFFFF);

  // Primary
  static const primary = Color(0xFF5B7FA2);
  static const accent = Color(0xFFE8A87C);

  // Text
  static const textPrimary = Color(0xFF3D3D3D);
  static const textSecondary = Color(0xFF8E8E8E);

  // Semantic
  static const income = Color(0xFF5BA37C);
  static const expense = Color(0xFFD4845A);

  // Utility
  static const divider = Color(0xFFE8E5DE);
  static const error = Color(0xFFD4845A);

  // Legacy aliases (gradual migration)
  static const paper = background;
  static const inkBlue = primary;
  static const inkPurple = primary;
  static const inkBlack = textPrimary;
  static const inkRed = error;
}
