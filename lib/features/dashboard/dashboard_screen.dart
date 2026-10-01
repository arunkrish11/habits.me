import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/backup_service.dart';
import '../../core/date_utils.dart';
import '../../core/habit_icons.dart';
import '../../core/haptic_service.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
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

  // The order you just dropped. It is shown right away, so the list does not
  // jump back while the database is still saving.
  List<int> _pending = [];

  List<Habit> _ordered(List<Habit> items) {
    if (_pending.isEmpty) return items;
    final ids = items.map((h) => h.id).toList();
    if (listEquals(ids, _pending)) {
      _pending = []; // the database has caught up
      return items;
    }
    final pos = {for (var i = 0; i < _pending.length; i++) _pending[i]: i};
    if (!ids.every(pos.containsKey)) return items; // belongs to the other list
    return [...items]..sort((a, b) => pos[a.id]!.compareTo(pos[b.id]!));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => BackupService.runIfDue(ref.read(dbProvider)),
    );
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

  // Long press a habit, then drag it to a new position
  Widget _group(List<Habit> items, bool votes, List<HabitLog> logs) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorderStart: (_) => HapticService.tap(),
      proxyDecorator: (child, index, animation) =>
          Material(color: Colors.transparent, child: child),
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final list = [...items];
            list.insert(newIndex, list.removeAt(oldIndex));
            setState(() => _pending = list.map((h) => h.id).toList());
            ref.read(dbProvider).reorder(list);
          },
      children: [
        for (var i = 0; i < items.length; i++)
          ReorderableDelayedDragStartListener(
            key: ValueKey(items[i].id),
            index: i,
            child: _HabitTile(
              habit: items[i],
              logs: logs.where((l) => l.habitId == items[i].id).toList(),
              day: _day,
              showVotes: votes,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final habits = ref.watch(habitsProvider).value ?? [];
    final logs = ref.watch(allLogsProvider).value ?? [];
    final active =
        _ordered(habits.where((h) => !endedBefore(h, _day)).toList());
    final inactive =
        _ordered(habits.where((h) => endedBefore(h, _day)).toList());
        
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
              if (_day != dateOnly(DateTime.now())) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Viewing ${DateFormat('d MMM').format(_day)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _day = dateOnly(DateTime.now())),
                        child: const Text('Back to today'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    const Text('Active'),
                    if (active.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No active habits yet. Tap New to create one.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    _group(active, true, logs),
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
                      if (_showInactive) _group(inactive, false, logs),
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
        leading: HabitIcon(habit),
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
