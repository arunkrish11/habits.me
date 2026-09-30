import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/date_utils.dart';
import 'app_database.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final habitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(dbProvider).watchHabits(),
);

final todayLogsProvider = StreamProvider<List<HabitLog>>(
  (ref) => ref.watch(dbProvider).watchLogsForDay(dayKey(DateTime.now())),
);