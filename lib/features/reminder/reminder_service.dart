import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:vintage_ledger/core/service_locator.dart';

class ReminderService {
  static const _channelId = 'daily_reminder';
  static const _channelName = 'Daily Reminder';
  static const _notificationId = 1001;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;

  static const _messages = [
    'reminderMsg1',
    'reminderMsg2',
    'reminderMsg3',
    'reminderMsg4',
  ];

  static void setNavigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Reschedule if enabled
    final enabled = await sl.settingService.getSetting('reminder_enabled');
    if (enabled == 'true') {
      final hour = int.tryParse(await sl.settingService.getSetting('reminder_hour') ?? '20') ?? 20;
      await schedule(hour);
    }
  }

  static void _onTap(NotificationResponse response) {
    // Navigate to home — MainShell is already the root
  }

  static Future<void> schedule(int hour) async {
    await _plugin.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final msgKey = _messages[Random().nextInt(_messages.length)];

    // We use a fixed title + body since l10n context isn't available here.
    // Messages are in Vietnamese as default locale.
    const title = 'Vintage Ledger';
    final body = _messageText(msgKey);

    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancel(_notificationId);
  }

  static String _messageText(String key) => switch (key) {
    'reminderMsg1' => 'Hôm nay bạn đã tiêu gì chưa?',
    'reminderMsg2' => 'Ghi lại chi tiêu hôm nay chỉ mất 5 giây 👇',
    'reminderMsg3' => 'Đừng quên ghi chép thu chi hôm nay nhé!',
    'reminderMsg4' => 'Một ngày nữa trôi qua — bạn đã ghi chép chưa?',
    _ => 'Hôm nay bạn đã tiêu gì chưa?',
  };
}
