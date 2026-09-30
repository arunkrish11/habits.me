import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    final dynamic t = await FlutterTimezone.getLocalTimezone();
    final name = t is String ? t : t.identifier as String;
    tz.setLocalLocation(tz.getLocation(name));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  static Future<TimeOfDay?> savedTime() async {
    final p = await SharedPreferences.getInstance();
    final m = p.getInt('reminder_minutes');
    return m == null ? null : TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

  // Returns false if the user denied the notification permission
  static Future<bool> setReminder(TimeOfDay time) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    if (granted == false) return false;

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));

    await _plugin.zonedSchedule(
      id: 1,
      title: 'habits.me',
      body: 'Time to check in on your habits',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );

    final p = await SharedPreferences.getInstance();
    await p.setInt('reminder_minutes', time.hour * 60 + time.minute);
    return true;
  }

  static Future<void> clear() async {
    await _plugin.cancel(id: 1);
    final p = await SharedPreferences.getInstance();
    await p.remove('reminder_minutes');
  }
}
