import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  // 0 = per day, 1 = per week (per week is no longer used)
  IntColumn get repeatMode => integer().withDefault(const Constant(0))();
  IntColumn get weekdays => integer().withDefault(const Constant(127))();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get icon => integer().withDefault(const Constant(0))();
  // Custom emoji. Empty = use the icon above.
  TextColumn get emoji => text().withDefault(const Constant(''))();
  // Position in the list (smaller = higher)
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(habitLogs, habitLogs.status);
      }
      if (from < 3) {
        await m.addColumn(habits, habits.icon);
      }
      if (from < 4) {
        await m.addColumn(habits, habits.emoji);
        await m.addColumn(habits, habits.sortOrder);
        await customStatement('UPDATE habits SET sort_order = id');
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<Habit>> watchHabits() =>
      (select(habits)..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.id),
          ]))
          .watch();

  // New habits go to the end of the list
  Future<int> addHabit(HabitsCompanion habit) async {
    final maxExpr = habits.sortOrder.max();
    final row = await (selectOnly(habits)..addColumns([maxExpr])).getSingle();
    final next = (row.read(maxExpr) ?? 0) + 1;
    return into(habits).insert(habit.copyWith(sortOrder: Value(next)));
  }

  Future<void> setActive(int id, bool active) =>
      (update(habits)..where((t) => t.id.equals(id))).write(
        HabitsCompanion(isActive: Value(active)),
      );

  Future<void> updateHabit(int id, HabitsCompanion data) =>
      (update(habits)..where((t) => t.id.equals(id))).write(data);

  // Its logs are deleted too (cascade)
  Future<void> deleteHabit(int id) =>
      (delete(habits)..where((t) => t.id.equals(id))).go();

  // Saves a new order for one group (active or inactive).
  // It reuses the group's own positions, so the other group is not affected.
  Future<void> reorder(List<Habit> newOrder) => transaction(() async {
    final slots = newOrder.map((h) => h.sortOrder).toList()..sort();
    for (var i = 0; i < newOrder.length; i++) {
      await (update(habits)..where((t) => t.id.equals(newOrder[i].id))).write(
        HabitsCompanion(sortOrder: Value(slots[i])),
      );
    }
  });

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
