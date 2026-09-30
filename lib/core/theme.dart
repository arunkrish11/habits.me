import 'package:flutter/material.dart';

class ThemePreset {
  const ThemePreset(this.name, this.background, this.card, this.accent);
  final String name;
  final Color background, card, accent;
}

const presets = [
  ThemePreset('Blue', Color(0xFF1A2B5A), Color(0xFF2D4499), Color(0xFF0044FF)),
  ThemePreset('Green', Color(0xFF12301F), Color(0xFF1F5A3A), Color(0xFF00C853)),
  ThemePreset(
    'Purple',
    Color(0xFF2A1A4A),
    Color(0xFF4A3399),
    Color(0xFF7C4DFF),
  ),
  ThemePreset(
    'Orange',
    Color(0xFF3A2412),
    Color(0xFF8A4B1F),
    Color(0xFFFF6D00),
  ),
  ThemePreset('Red', Color(0xFF3A1418), Color(0xFF8A2E3A), Color(0xFFFF1744)),
];

class AppColors {
  static int index = 0;
  static Color background = presets[0].background;
  static Color card = presets[0].card;
  static Color accent = presets[0].accent;
  static Color get dim => background;

  static void apply(ThemePreset p, int i) {
    index = i;
    background = p.background;
    card = p.card;
    accent = p.accent;
  }
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'monospace',
    colorScheme: ColorScheme.dark(primary: AppColors.accent),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}
