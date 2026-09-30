import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final habitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(dbProvider).watchHabits(),
);

final allLogsProvider = StreamProvider<List<HabitLog>>(
  (ref) => ref.watch(dbProvider).watchAllLogs(),
);
