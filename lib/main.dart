import 'core/notification_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'features/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final prefs = await SharedPreferences.getInstance();
  final i = (prefs.getInt('theme_index') ?? 0).clamp(0, presets.length - 1);
  AppColors.apply(presets[i], i);
  runApp(const ProviderScope(child: HabitsApp()));
}

class HabitsApp extends ConsumerWidget {
  const HabitsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    return MaterialApp(
      title: 'habits.me',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const DashboardScreen(),
    );
  }
}
