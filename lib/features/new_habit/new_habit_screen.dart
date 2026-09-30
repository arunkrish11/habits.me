import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';

class NewHabitScreen extends ConsumerStatefulWidget {
  const NewHabitScreen({super.key});

  @override
  ConsumerState<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends ConsumerState<NewHabitScreen> {
  final _title = TextEditingController();
  int _mode = 0; // 0 = per day, 1 = per week
  int _weekdays = 127;
  DateTime? _endDate;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _endDate ?? DateTime.now(),
    );
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(dbProvider).addHabit(HabitsCompanion.insert(
            title: title,
            repeatMode: Value(_mode),
            weekdays: Value(_weekdays),
            endDate: Value(_endDate),
          ));
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        leadingWidth: 90,
        title: const Text('New Habit'),
        centerTitle: true,
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.card,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Repeat Mode'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Per Day')),
                ButtonSegment(value: 1, label: Text('Per Week')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_mode == 1) ...[
              const SizedBox(height: 24),
              const Text('Repeat On'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final on = (_weekdays & (1 << i)) != 0;
                  return GestureDetector(
                    onTap: () => setState(() => _weekdays ^= (1 << i)),
                    child: CircleAvatar(
                      backgroundColor:
                          on ? AppColors.accent : AppColors.card,
                      child: Text(_dayLabels[i]),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),
            const Text('End Date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.card,
                child: Text(_endDate == null
                    ? 'No end date'
                    : DateFormat('d MMM, y').format(_endDate!)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}