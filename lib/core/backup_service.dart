import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';

class BackupService {
  static Future<Directory> folder() async {
    final base =
        await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final d = Directory(p.join(base.path, 'backups'));
    await d.create(recursive: true);
    return d;
  }

  static String fileName() =>
      '${DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now())}.json';

  static Future<String> buildJson(AppDatabase db) async {
    final habits = await db.select(db.habits).get();
    final logs = await db.select(db.habitLogs).get();
    return jsonEncode({
      'version': 1,
      'habits': [
        for (final h in habits)
          {
            'id': h.id,
            'title': h.title,
            'repeatMode': h.repeatMode,
            'weekdays': h.weekdays,
            'endDate': h.endDate?.toIso8601String(),
            'isActive': h.isActive,
            'createdAt': h.createdAt.toIso8601String(),
          },
      ],
      'logs': [
        for (final l in logs)
          {'id': l.id, 'habitId': l.habitId, 'day': l.day, 'status': l.status},
      ],
    });
  }

  // Replaces ALL current data with the backup
  static Future<void> restoreFromString(AppDatabase db, String text) async {
    final data = jsonDecode(text) as Map<String, dynamic>;
    await db.transaction(() async {
      await db.delete(db.habitLogs).go();
      await db.delete(db.habits).go();
      for (final h in data['habits'] as List) {
        await db
            .into(db.habits)
            .insert(
              HabitsCompanion.insert(
                id: Value(h['id'] as int),
                title: h['title'] as String,
                repeatMode: Value(h['repeatMode'] as int),
                weekdays: Value(h['weekdays'] as int),
                endDate: Value(
                  h['endDate'] == null
                      ? null
                      : DateTime.parse(h['endDate'] as String),
                ),
                isActive: Value(h['isActive'] as bool),
                createdAt: Value(DateTime.parse(h['createdAt'] as String)),
              ),
            );
      }
      for (final l in data['logs'] as List) {
        await db
            .into(db.habitLogs)
            .insert(
              HabitLogsCompanion.insert(
                id: Value(l['id'] as int),
                habitId: l['habitId'] as int,
                day: l['day'] as String,
                status: Value(l['status'] as int),
              ),
            );
      }
    });
  }

  static Future<bool> autoEnabled() async =>
      (await SharedPreferences.getInstance()).getBool('auto_backup') ?? false;

  static Future<void> setAuto(bool on) async =>
      (await SharedPreferences.getInstance()).setBool('auto_backup', on);

  // Runs when the app opens: one backup per day, keeps the last 10
  static Future<void> runIfDue(AppDatabase db) async {
    if (!await autoEnabled()) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString('last_auto_backup') == today) return;

    final dir = await folder();
    await File(p.join(dir.path, 'auto_${fileName()}'))
        .writeAsString(await buildJson(db));
    await prefs.setString('last_auto_backup', today);

    final autos =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith('auto_'))
            .toList()
          ..sort((a, b) => b.path.compareTo(a.path));
    for (final old in autos.skip(10)) {
      await old.delete();
    }
  }
}
