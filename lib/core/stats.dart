import '../data/app_database.dart';
import 'date_utils.dart';

class HabitStats {
  const HabitStats(this.consistency, this.current, this.longest);
  final int consistency; // percent, last 30 days
  final int current;
  final int longest;
}

HabitStats calcStats(Habit habit, List<HabitLog> logs) {
  final byDay = {for (final l in logs) l.day: l.status};
  final done = <String>{
    for (final l in logs)
      if (l.status == 1) l.day,
  };

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayStatus = byDay[dayKey(today)] ?? 0;

  // Consistency: done days in the last 30 days / 30.
  // If today has no vote yet, the window ends yesterday.
  final end = todayStatus == 0
      ? DateTime(today.year, today.month, today.day - 1)
      : today;
  var doneIn30 = 0;
  for (var i = 0; i < 30; i++) {
    final d = DateTime(end.year, end.month, end.day - i);
    if (byDay[dayKey(d)] == 1) doneIn30++;
  }
  final consistency = (doneIn30 * 100 / 30).round();

  // Current streak: 0 if today is missed.
  // If today has no vote yet, count back from yesterday.
  var current = 0;
  if (todayStatus != -1) {
    var d = todayStatus == 1
        ? today
        : DateTime(today.year, today.month, today.day - 1);
    while (done.contains(dayKey(d))) {
      current++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
  }

  // Longest streak
  final sorted = done.map((s) => DateTime.parse('${s}T00:00:00Z')).toList()
    ..sort();
  var longest = 0, run = 0;
  DateTime? prev;
  for (final day in sorted) {
    run = (prev != null && day.difference(prev).inDays == 1) ? run + 1 : 1;
    if (run > longest) longest = run;
    prev = day;
  }

  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // True if the habit's end date is before the given day
  bool endedBefore(Habit h, DateTime day) =>
      h.endDate != null && dateOnly(h.endDate!).isBefore(dateOnly(day));

  return HabitStats(consistency, current, longest);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// True if the habit's end date is before the given day
bool endedBefore(Habit h, DateTime day) =>
    h.endDate != null && dateOnly(h.endDate!).isBefore(dateOnly(day));
