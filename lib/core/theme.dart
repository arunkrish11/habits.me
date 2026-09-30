import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF1A2B5A);
  static const card = Color(0xFF2D4499);
  static const accent = Color(0xFF0044FF);
  static const dim = Color(0xFF1A2B5A);
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'monospace',
  colorScheme: const ColorScheme.dark(primary: AppColors.accent),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
  ),
);