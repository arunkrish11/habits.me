import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TimeOfDay? _reminder;

  @override
  void initState() {
    super.initState();
    NotificationService.savedTime().then((t) {
      if (mounted) setState(() => _reminder = t);
    });
  }

  void _soon() =>
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Coming soon')));

  Future<void> _pickTime() async {
    final messenger = ScaffoldMessenger.of(context);
    final t = await showTimePicker(
      context: context,
      initialTime: _reminder ?? const TimeOfDay(hour: 23, minute: 0),
    );
    if (t == null) return;
    final ok = await NotificationService.setReminder(t);
    if (!mounted) return;
    if (ok) {
      setState(() => _reminder = t);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification permission denied')),
      );
    }
  }

  Future<void> _turnOff() async {
    await NotificationService.clear();
    if (mounted) setState(() => _reminder = null);
  }

  Widget _group(List<String> items) => Container(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [for (final t in items) ListTile(title: Text(t), onTap: _soon)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Theme Color'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < presets.length; i++)
                  GestureDetector(
                    onTap: () => ref.read(themeProvider.notifier).select(i),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: presets[i].accent,
                        shape: BoxShape.circle,
                        border: i == selected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Notifications'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(
                _reminder == null ? 'Off' : _reminder!.format(context),
              ),
              onTap: _pickTime,
              trailing: _reminder == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _turnOff,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Backups'),
          const SizedBox(height: 8),
          _group(['Create', 'Restore', 'Auto Backup']),
          const SizedBox(height: 16),
          _group(['Report Issues', 'Open Source', 'Privacy']),
        ],
      ),
    );
  }
}
