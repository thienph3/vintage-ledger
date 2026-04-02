# Tasks: Daily Reminder (Local Notification)

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Thêm dependency | `pubspec.yaml` | `flutter_local_notifications` + `timezone` |
| 2 | ReminderService | `lib/features/reminder/reminder_service.dart` | Init plugin, request permission, `scheduleDailyReminder()`, `cancelReminder()` |
| 3 | Check transaction hôm nay | `ReminderService` | Query `transactions` where date = today, nếu empty → schedule notification |
| 4 | Schedule logic | `ReminderService` | `zonedSchedule()` daily lúc 20:00 (hoặc giờ user chọn), `matchDateTimeComponents: DateTimeComponents.time` |
| 5 | Message ngẫu nhiên | `ReminderService` | List 3–5 messages, random pick: "Hôm nay bạn đã tiêu gì chưa?", "Ghi lại chi tiêu chỉ mất 5 giây 👇" |
| 6 | Settings toggle | `lib/features/settings/screens/setting_screen.dart` | SwitchListTile "Nhắc nhở hàng ngày" + TimePicker chọn giờ |
| 7 | Persist settings | `SettingService` | `reminder_enabled` (bool), `reminder_hour` (int) trong Firestore user settings |
| 8 | Init khi mở app | `main.dart` | Gọi `ReminderService.init()` non-blocking trong `_init()` |
| 9 | Handle tap notification | `ReminderService` | `onDidReceiveNotificationResponse` → navigate to HomeScreen |
| 10 | L10n keys | `app_vi.dart`, `app_en.dart` | +4 keys: dailyReminder, reminderTime, reminderMsg1, reminderMsg2 |
| 11 | Android config | `android/app/src/main/AndroidManifest.xml` | `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` permissions |
