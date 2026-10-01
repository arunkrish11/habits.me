import 'package:drift/drift.dart' show Value;
import 'emoji_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/habit_icons.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../data/app_database.dart';
import '../../data/providers.dart';

class NewHabitScreen extends ConsumerStatefulWidget {
  const NewHabitScreen({super.key, this.habit});
  final Habit? habit; // null = create, set = edit

  @override
  ConsumerState<NewHabitScreen> createState() => _NewHabitScreenState();
}

class _NewHabitScreenState extends ConsumerState<NewHabitScreen> {
  final _title = TextEditingController();
  String _emoji = ''; // empty = use the icon grid
  int _icon = 0;
  DateTime? _endDate;

  bool get _editing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    if (h != null) {
      _title.text = h.title;
      _icon = h.icon;
      _emoji = h.emoji;
      _endDate = h.endDate;
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

  Future<void> _pickEmoji() async {
    FocusScope.of(context).unfocus();
    final emoji = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const EmojiScreen(),
      ),
    );
    if (emoji != null) setState(() => _emoji = emoji);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    if (_endDate == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select an end date')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final db = ref.read(dbProvider);
    try {
      if (_editing) {
        await db.updateHabit(
          widget.habit!.id,
          HabitsCompanion(
            title: Value(title),
            icon: Value(_icon),
            emoji: Value(_emoji),
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
            emoji: Value(_emoji),
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
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: const Text('This also deletes its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    final usingEmoji = _emoji.isNotEmpty;
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
                borderRadius: BorderRadius.circular(12),
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
                  onTap: () => setState(() {
                    _icon = i;
                    _emoji = '';
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (i == _icon && !usingEmoji)
                          ? AppColors.accent
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(habitIcons[i]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Custom emoji'),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _pickEmoji,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: usingEmoji ? AppColors.accent : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: usingEmoji
                      ? Text(_emoji, style: const TextStyle(fontSize: 28))
                      : const Icon(Icons.add_reaction_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  usingEmoji ? 'Tap to change' : 'Tap to choose an emoji',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if (usingEmoji)
                IconButton(
                  tooltip: 'Remove emoji',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _emoji = ''),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('End Date'),
          const SizedBox(height: 8),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Text(
                  _endDate == null
                      ? 'Select end date'
                      : DateFormat('d MMM, y').format(_endDate!),
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
                  borderRadius: BorderRadius.circular(12),
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
