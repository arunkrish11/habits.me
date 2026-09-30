import '../../core/theme_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/date_utils.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../core/vote_buttons.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../new_habit/new_habit_screen.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habit});
  final Habit habit;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Widget _statRow(String value, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    ),
  );

  Widget _dayCircle(int day, Map<String, int> byDay) {
    final date = DateTime(_month.year, _month.month, day);
    final now = DateTime.now();
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
    final isSelected = date == _selected;
    final status = byDay[dayKey(date)] ?? 0;
    final color = status == 1
        ? AppColors.accent
        : status == -1
        ? const Color(0xFF8B2E3C)
        : AppColors.background;
    return GestureDetector(
      onTap: isFuture ? null : () => setState(() => _selected = date),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 12,
            color: isFuture ? Colors.white24 : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the live copy so edits show up right away
    ref.watch(themeProvider);
    final habit =
        (ref.watch(habitsProvider).value ?? [])
            .where((h) => h.id == widget.habit.id)
            .firstOrNull ??
        widget.habit;
    final logs = (ref.watch(allLogsProvider).value ?? [])
        .where((l) => l.habitId == habit.id)
        .toList();
    final stats = calcStats(habit, logs);
    final ended = endedBefore(habit, DateTime.now());
    final byDay = {for (final l in logs) l.day: l.status};
    final selectedKey = dayKey(_selected);
    final selectedStatus = byDay[selectedKey] ?? 0;

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday % 7;
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NewHabitScreen(habit: habit)),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _statRow('${stats.consistency}%', 'Consistency Score'),
                _statRow('${stats.current} days', 'Current Streak'),
                _statRow('${stats.longest} days', 'Longest Streak'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(DateFormat('MMMM y').format(_month)),
                    IconButton(
                      onPressed: () => _shift(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final l in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                      Expanded(
                        child: Center(
                          child: Text(
                            l,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < offset; i++) const SizedBox(),
                    for (var d = 1; d <= daysInMonth; d++) _dayCircle(d, byDay),
                  ],
                ),
              ],
            ),
          ),
          if (!ended) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.title),
                        Text(
                          DateFormat('EEE, d MMM').format(_selected),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  VoteButtons(
                    habitId: habit.id,
                    status: selectedStatus,
                    percent: stats.consistency,
                    day: selectedKey,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
