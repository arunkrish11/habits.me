import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  IntColumn get icon => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get day => text()(); // yyyy-MM-dd
  // 1 = done (upvote), -1 = missed (downvote)
  IntColumn get status => integer().withDefault(const Constant(1))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

@DriftDatabase(tables: [Habits, HabitLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'habits'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(habitLogs, habitLogs.status);
      }
      if (from < 3) {
        await m.addColumn(habits, habits.icon);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<Habit>> watchHabits() => select(habits).watch();

  Future<int> addHabit(HabitsCompanion habit) => into(habits).insert(habit);

  Future<void> setActive(int id, bool active) =>
      (update(habits)..where((t) => t.id.equals(id))).write(
        HabitsCompanion(isActive: Value(active)),
      );

  Future<void> updateHabit(int id, HabitsCompanion data) =>
      (update(habits)..where((t) => t.id.equals(id))).write(data);

  // Its logs are deleted too (cascade)
  Future<void> deleteHabit(int id) =>
      (delete(habits)..where((t) => t.id.equals(id))).go();

  Stream<List<HabitLog>> watchAllLogs() => select(habitLogs).watch();

  // Same button again = clear. Other button = switch.
  Future<void> setStatus(int habitId, String day, int status) => transaction(
    () async {
      final existing =
          await (select(habitLogs)
                ..where((t) => t.habitId.equals(habitId) & t.day.equals(day)))
              .getSingleOrNull();
      if (existing != null) {
        await (delete(habitLogs)..where((t) => t.id.equals(existing.id))).go();
      }
      if (existing?.status != status) {
        await into(habitLogs).insert(
          HabitLogsCompanion.insert(
            habitId: habitId,
            day: day,
            status: Value(status),
          ),
        );
      }
    },
  );
}
