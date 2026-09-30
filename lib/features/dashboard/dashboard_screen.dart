import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../new_habit/new_habit_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider).value ?? [];
    final logs = ref.watch(todayLogsProvider).value ?? [];
    final doneIds = logs.map((l) => l.habitId).toSet();
    final active = habits.where((h) => h.isActive).toList();
    final inactive = habits.where((h) => !h.isActive).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('habits.me',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(DateFormat('EEE, MMM d').format(DateTime.now())),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    const Text('Active'),
                    ...active.map((h) => _HabitTile(
                        habit: h, done: doneIds.contains(h.id))),
                    const SizedBox(height: 24),
                    const Text('Inactive'),
                    ...inactive.map((h) => _HabitTile(
                        habit: h, done: doneIds.contains(h.id))),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.card),
                    onPressed: () {}, // Settings screen comes next
                    child: const Text('Settings'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.card),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NewHabitScreen()),
                    ),
                    child: const Text('New'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({required this.habit, required this.done});
  final Habit habit;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(dbProvider);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        // Tap toggles today's check, long press moves active <-> inactive
        onTap: () => db.toggleLog(habit.id, dayKey(DateTime.now())),
        onLongPress: () => db.setActive(habit.id, !habit.isActive),
        title: Text(habit.title),
        trailing: Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          color: done ? Colors.white : Colors.white54,
        ),
      ),
    );
  }
}