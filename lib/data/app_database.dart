import 'dart:io' show Platform;
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  // 0 = per day, 1 = per week
  IntColumn get repeatMode => integer().withDefault(const Constant(0))();
  // bitmask: bit 0 = Mon ... bit 6 = Sun (127 = all days)
  IntColumn get weekdays => integer().withDefault(const Constant(127))();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()(); // yyyy-MM-dd

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, day},
      ];
}

@DriftDatabase(tables: [Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(driftDatabase(
          name: 'habits',
          native: DriftNativeOptions(
            databasePath: () async {
              // Android: use the default private storage
              if (Platform.isAndroid) {
                final dir = await getApplicationDocumentsDirectory();
                return p.join(dir.path, 'habits.sqlite');
              }
              // Windows: save in the Downloads folder
              final dir = await getDownloadsDirectory();
              return p.join(dir!.path, 'habits.sqlite');
            },
          ),
        ));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Stream<List<Habit>> watchHabits() => select(habits).watch();

  Future<int> addHabit(HabitsCompanion habit) => into(habits).insert(habit);

  Future<void> setActive(int id, bool active) =>
      (update(habits)..where((t) => t.id.equals(id)))
          .write(HabitsCompanion(isActive: Value(active)));

  Stream<List<HabitLog>> watchLogsForDay(String day) =>
      (select(habitLogs)..where((t) => t.day.equals(day))).watch();

  Future<void> toggleLog(int habitId, String day) async {
    final existing = await (select(habitLogs)
          ..where((t) => t.habitId.equals(habitId) & t.day.equals(day)))
        .getSingleOrNull();
    if (existing == null) {
      await into(habitLogs)
          .insert(HabitLogsCompanion.insert(habitId: habitId, day: day));
    } else {
      await (delete(habitLogs)..where((t) => t.id.equals(existing.id))).go();
    }
  }
}