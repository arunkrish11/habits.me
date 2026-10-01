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
  ThemePreset('Black', Color(0xFF000000), Color(0xFF1C1C1E), Color(0xFF3D8BFF)),
  ThemePreset(
    'Charcoal',
    Color(0xFF121212),
    Color(0xFF2A2A2E),
    Color(0xFF7A7F8C),
  ),
  ThemePreset(
    'Midnight',
    Color(0xFF0A0F1E),
    Color(0xFF18213D),
    Color(0xFF4C6FFF),
  ),
  ThemePreset(
    'Dark Forest',
    Color(0xFF0B1A12),
    Color(0xFF16301F),
    Color(0xFF2E9E5B),
  ),
  ThemePreset(
    'Dark Teal',
    Color(0xFF0A1C1E),
    Color(0xFF133538),
    Color(0xFF14A3A8),
  ),
  ThemePreset('Wine', Color(0xFF1E0A12), Color(0xFF3D1526), Color(0xFFC2185B)),
  ThemePreset(
    'Coffee',
    Color(0xFF1A120B),
    Color(0xFF3A2A1C),
    Color(0xFFC27C3A),
  ),
  ThemePreset('Plum', Color(0xFF1A0B1F), Color(0xFF3A1B45), Color(0xFFB04DD6)),
  ThemePreset('Olive', Color(0xFF14150A), Color(0xFF2E3115), Color(0xFF9CAF2B)),
  ThemePreset('Amber', Color(0xFF1A1505), Color(0xFF3A3010), Color(0xFFF5B800)),
];

class AppColors {
  static int index = 0;
  static const Color text = Colors.white;
  static Color background = presets[0].background;
  static Color card = presets[0].card;
  static Color accent = presets[0].accent;
  static Color get dim => background;

  static void apply(int i) {
    index = i;
    final p = presets[i];
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
