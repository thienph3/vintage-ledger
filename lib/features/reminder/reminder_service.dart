// ignore_for_file: use_build_context_synchronously
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/core/service_locator.dart';

class ReminderService {
  static const _channelId = 'daily_reminder';
  static const _channelName = 'Daily Reminder';
  static const _notificationId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _messageKeys = [
    'reminderMsg1',
    'reminderMsg2',
    'reminderMsg3',
    'reminderMsg4',
  ];

  Future<void> init(BuildContext context) async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    final enabled = await sl.settingService.getSetting('reminder_enabled');
    if (enabled == 'true') {
      final hourStr = await sl.settingService.getSetting('reminder_hour');
      final hour = int.tryParse(hourStr ?? '20') ?? 20;
      if (context.mounted) await schedule(context, hour);
    }
  }

  void _onTap(NotificationResponse response) {}

  Future<void> schedule(BuildContext context, int hour) async {
    await _plugin.cancel(id: _notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final key = _messageKeys[Random().nextInt(_messageKeys.length)];
    final body = S.of(context, key);

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Vintage Ledger',
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await _plugin.cancel(id: _notificationId);
  }
}
