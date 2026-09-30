import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backup_service.dart';
import '../../core/notification_service.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../data/providers.dart';
import 'privacy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TimeOfDay? _reminder;
  bool _auto = false;

  @override
  void initState() {
    super.initState();
    NotificationService.savedTime().then((t) {
      if (mounted) setState(() => _reminder = t);
    });
    BackupService.autoEnabled().then((v) {
      if (mounted) setState(() => _auto = v);
    });
  }

  void _msg(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pickTime() async {
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
      _msg('Notification permission denied');
    }
  }

  Future<void> _turnOff() async {
    await NotificationService.clear();
    if (mounted) setState(() => _reminder = null);
  }

  Future<void> _create() async {
    try {
      final json = await BackupService.buildJson(ref.read(dbProvider));
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save backup',
        fileName: BackupService.fileName(),
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (saved != null) _msg('Backup saved');
    } catch (e) {
      _msg('Error: $e');
    }
  }

  Future<void> _restore() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text('This replaces all current habits and history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final text = utf8.decode(await file.readAsBytes());
      await BackupService.restoreFromString(ref.read(dbProvider), text);
      _msg('Backup restored');
    } catch (e) {
      _msg('Restore failed: $e');
    }
  }

  Future<void> _toggleAuto(bool v) async {
    await BackupService.setAuto(v);
    setState(() => _auto = v);
  }

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: children),
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
          _card([
            ListTile(
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
          ]),
          const SizedBox(height: 24),
          const Text('Backups'),
          const SizedBox(height: 8),
          _card([
            ListTile(title: const Text('Create'), onTap: _create),
            ListTile(title: const Text('Restore'), onTap: _restore),
            ListTile(
              title: const Text('Auto Backup'),
              trailing: Switch(value: _auto, onChanged: _toggleAuto),
              onTap: () => _toggleAuto(!_auto),
            ),
          ]),
          const SizedBox(height: 16),
          _card([
            ListTile(
              title: const Text('Report Issues'),
              onTap: () =>
                  _open('https://github.com/arunkrish11/habits.me/issues'),
            ),
            ListTile(
              title: const Text('Open Source'),
              onTap: () => _open('https://github.com/arunkrish11/habits.me'),
            ),
            ListTile(
              title: const Text('Privacy'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
