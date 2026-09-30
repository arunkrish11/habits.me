import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

class ThemeNotifier extends Notifier<int> {
  @override
  int build() => AppColors.index;

  Future<void> select(int i) async {
    AppColors.apply(presets[i], i);
    state = i;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', i);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, int>(ThemeNotifier.new);
