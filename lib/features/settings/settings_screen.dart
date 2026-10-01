import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/backup_service.dart';
import '../../core/haptic_service.dart';
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

  // ---- Notifications ----
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

  Future<void> _toggleReminder(bool on) async {
    if (on) {
      await _pickTime();
    } else {
      await NotificationService.clear();
      if (mounted) setState(() => _reminder = null);
    }
  }

  // ---- Backups ----
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
          const Text('Theme'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (var i = 0; i < presets.length; i++)
                  Tooltip(
                    message: presets[i].name,
                    child: GestureDetector(
                      onTap: () => ref.read(themeProvider.notifier).select(i),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: presets[i].background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == selected
                                ? Colors.white
                                : Colors.white24,
                            width: i == selected ? 3 : 1,
                          ),
                        ),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: presets[i].accent,
                            shape: BoxShape.circle,
                          ),
                        ),
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
            SwitchListTile(
              title: const Text('Daily reminder'),
              value: _reminder != null,
              onChanged: _toggleReminder,
            ),
            if (_reminder != null)
              ListTile(
                title: const Text('Time'),
                trailing: Text(_reminder!.format(context)),
                onTap: _pickTime,
              ),
          ]),
          const SizedBox(height: 24),
          const Text('Haptic feedback'),
          const SizedBox(height: 8),
          _card([
            SwitchListTile(
              title: const Text('Vibrate on tap'),
              value: HapticService.enabled,
              onChanged: (v) async {
                setState(() => HapticService.enabled = v);
                await HapticService.save();
                if (v) HapticService.tap();
              },
            ),
            if (HapticService.enabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vibration level'),
                    Slider(
                      value: HapticService.level,
                      onChanged: (v) => setState(() => HapticService.level = v),
                      onChangeEnd: (_) async {
                        await HapticService.save();
                        HapticService.tap();
                      },
                    ),
                  ],
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
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, s) => Center(
              child: Text(
                s.hasData ? 'v${s.data!.version} (${s.data!.buildNumber})' : '',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
