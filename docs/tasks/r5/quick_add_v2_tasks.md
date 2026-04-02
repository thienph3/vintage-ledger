# Tasks: Quick Add V2 — Smart Suggestions — ✅

| # | Task | Status |
|---|------|--------|
| 1 | QuickAddEntry model | ✅ `lib/features/quick_add/models/quick_add_entry.dart`: text, categoryId, amount, count, lastUsed + encode/decode |
| 2 | Lưu history khi submit | ✅ `QuickAddHistory.record()` gọi sau submit thành công trong `quick_add_bar.dart` |
| 3 | Persist vào settings | ✅ `QuickAddHistory`: lưu vào `users/{uid}/settings` key `quick_add_history`, pipe-delimited entries, newline-separated |
| 4 | Load suggestions | ✅ `QuickAddHistory.init()` trong `main.dart`, `suggest()` sort by count desc |
| 5 | Suggestion chips UI | ✅ `ActionChip` row hiện khi focus + text rỗng + có suggestions. Compact style |
| 6 | Tap chip → auto submit | ✅ `_applySuggestion()`: set text → trigger `_submit()` |
| 7 | Filter khi đang gõ | ✅ `_onChanged()` gọi `suggest(filter: text)` khi text không rỗng |
| 8 | Limit 20 entries | ✅ `_maxEntries = 20`, xóa least recently used khi vượt |
| 9 | Firestore rules | ✅ Dùng `users/{uid}/settings` — đã có rule |
| 10 | Flush on pause | ✅ `QuickAddHistory.flush()` trong `didChangeAppLifecycleState` |
