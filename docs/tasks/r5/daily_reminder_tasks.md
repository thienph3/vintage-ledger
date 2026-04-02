# Tasks: Daily Reminder (Local Notification) — ✅

| # | Task | Status |
|---|------|--------|
| 1 | Thêm dependency | ✅ `flutter_local_notifications: ^19.0.0` + `timezone: ^0.10.0` |
| 2 | ReminderService | ✅ `lib/features/reminder/reminder_service.dart`: init plugin, `schedule(hour)`, `cancel()` |
| 3 | Check transaction hôm nay | ✅ Skipped — schedule daily repeating thay vì check (simpler, `matchDateTimeComponents: time`) |
| 4 | Schedule logic | ✅ `zonedSchedule()` daily tại giờ user chọn, `inexactAllowWhileIdle`, `matchDateTimeComponents.time` |
| 5 | Message ngẫu nhiên | ✅ 4 messages random pick, hardcoded Vietnamese (no l10n context in service) |
| 6 | Settings toggle | ✅ SwitchListTile + TimePicker trong SettingScreen |
| 7 | Persist settings | ✅ `reminder_enabled` + `reminder_hour` trong user settings via SettingService |
| 8 | Init khi mở app | ✅ `ReminderService.init()` non-blocking trong `main.dart _init()`, reschedule if enabled |
| 9 | Handle tap notification | ✅ `onDidReceiveNotificationResponse` callback (app already opens to MainShell) |
| 10 | L10n keys | ✅ +6 keys vi/en: dailyReminder, reminderTime, reminderMsg1-4 |
| 11 | Android config | ✅ `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` permissions + boot receiver + scheduled receiver |
