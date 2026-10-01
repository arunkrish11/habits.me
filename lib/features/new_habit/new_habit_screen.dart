import '../../core/theme_provider.dart';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';
import '../../core/habit_icons.dart';

class NewHabitScreen extends ConsumerStatefulWidget {
  const NewHabitScreen({super.key, this.habit});
  final Habit? habit; // null = create, set = edit

  @override
  ConsumerState<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends ConsumerState<NewHabitScreen> {
  final _title = TextEditingController();
  DateTime? _endDate;
  int _icon = 0;
  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    if (h != null) {
      _title.text = h.title;
      _endDate = h.endDate;
      _icon = h.icon;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _endDate ?? DateTime.now(),
    );
    if (d != null) setState(() => _endDate = d);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an end date')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final db = ref.read(dbProvider);
    try {
      if (_editing) {
        await db.updateHabit(
          widget.habit!.id,
          HabitsCompanion(
            title: Value(title),
            icon: Value(_icon),
            repeatMode: const Value(0),
            weekdays: const Value(127),
            endDate: Value(_endDate),
          ),
        );
      } else {
        await db.addHabit(
          HabitsCompanion.insert(
            title: title,
            icon: Value(_icon),
            endDate: Value(_endDate),
          ),
        );
      }
      messenger.showSnackBar(const SnackBar(content: Text('Saved')));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('This also deletes its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(dbProvider).deleteHabit(widget.habit!.id);
    navigator.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    const radius = 12.0;
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        leadingWidth: 90,
        title: Text(_editing ? widget.habit!.title : 'New Habit'),
        centerTitle: true,
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Title'),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Icon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < habitIcons.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _icon = i),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: i == _icon ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(habitIcons[i], color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('End Date'),
          const SizedBox(height: 8),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _endDate == null
                            ? 'Select end date'
                            : DateFormat('d MMM, y').format(_endDate!),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_editing) ...[
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF962D2D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
              onPressed: _delete,
              child: const Text('Delete'),
            ),
          ],
        ],
      ),
    );
  }
}
