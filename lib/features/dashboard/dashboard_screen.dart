import '../../core/theme_provider.dart';
import '../../core/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/date_utils.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../core/vote_buttons.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../habit_detail/habit_detail_screen.dart';
import '../new_habit/new_habit_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _day = dateOnly(DateTime.now());
  bool _showInactive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => BackupService.runIfDue(ref.read(dbProvider)));
  }

  Future<void> _pickDay() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: dateOnly(DateTime.now()),
      initialDate: _day,
    );
    if (d != null) setState(() => _day = dateOnly(d));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final habits = ref.watch(habitsProvider).value ?? [];
    final logs = ref.watch(allLogsProvider).value ?? [];
    final active = habits.where((h) => !endedBefore(h, _day)).toList();
    final inactive = habits.where((h) => endedBefore(h, _day)).toList();

    Widget tile(Habit h, bool votes) => _HabitTile(
      habit: h,
      logs: logs.where((l) => l.habitId == h.id).toList(),
      day: _day,
      showVotes: votes,
    );

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
                  const Text(
                    'habits.me',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: _pickDay,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Text(DateFormat('EEE, MMM d').format(_day)),
                          const SizedBox(width: 6),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    const Text('Active'),
                    ...active.map((h) => tile(h, true)),
                    if (inactive.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () =>
                            setState(() => _showInactive = !_showInactive),
                        child: Row(
                          children: [
                            Text('Inactive (${inactive.length})'),
                            const SizedBox(width: 4),
                            Icon(
                              _showInactive
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                      ),
                      if (_showInactive) ...inactive.map((h) => tile(h, false)),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: const Text('Settings'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewHabitScreen()),
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

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.habit,
    required this.logs,
    required this.day,
    required this.showVotes,
  });
  final Habit habit;
  final List<HabitLog> logs;
  final DateTime day;
  final bool showVotes;

  @override
  Widget build(BuildContext context) {
    final key = dayKey(day);
    final dayLog = logs.where((l) => l.day == key).firstOrNull;
    final stats = calcStats(habit, logs);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
        ),
        title: Text(habit.title),
        trailing: showVotes
            ? VoteButtons(
                habitId: habit.id,
                status: dayLog?.status ?? 0,
                percent: stats.consistency,
                day: key,
              )
            : Text('${stats.consistency}%'),
      ),
    );
  }
}
