import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class HapticService {
  static bool enabled = true;
  static double level = 0.5; // 0.0 to 1.0
  static bool? _hasAmp;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    enabled = p.getBool('haptic_enabled') ?? true;
    level = p.getDouble('haptic_level') ?? 0.5;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('haptic_enabled', enabled);
    await p.setDouble('haptic_level', level);
  }

  // Phones with amplitude control use the strength.
  // Other phones get a longer or shorter buzz instead.
  static Future<void> tap() async {
    if (!enabled) return;
    try {
      if (await Vibration.hasVibrator() != true) return;
      _hasAmp ??= (await Vibration.hasAmplitudeControl()) == true;
      if (_hasAmp == true) {
        await Vibration.vibrate(
            duration: 30, amplitude: (level * 254 + 1).round());
      } else {
        await Vibration.vibrate(duration: (10 + level * 50).round());
      }
    } catch (_) {}
  }
}