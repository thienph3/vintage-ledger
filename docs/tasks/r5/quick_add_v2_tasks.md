# Tasks: Quick Add V2 — Smart Suggestions

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | QuickAddHistory model | `lib/features/quick_add/models/quick_add_entry.dart` | `{text, categoryId, amount, count, lastUsed}` |
| 2 | Lưu history khi submit | `quick_add_bar.dart` | Sau `_submit()` thành công → upsert entry vào Firestore `users/{uid}/quick_add_history/{hash}` |
| 3 | Firestore collection | `SettingService` hoặc riêng | `quick_add_history` subcollection dưới user, doc id = hash(text.lowercase), fields: text, category_id, amount, count, last_used |
| 4 | Load suggestions | `quick_add_bar.dart` | `_loadSuggestions()` trong initState → query top 5 by count desc, cache in-memory |
| 5 | Suggestion chips UI | `quick_add_bar.dart` | Hiện khi focus vào TextField + text rỗng. Row of `ActionChip` dưới input: "cafe 30k", "ăn trưa 50k" |
| 6 | Tap chip → auto submit | `quick_add_bar.dart` | Set `_ctrl.text = entry.text` → gọi `_submit()` trực tiếp |
| 7 | Filter khi đang gõ | `quick_add_bar.dart` | Khi text không rỗng → filter suggestions startsWith text → hiện matching chips |
| 8 | Limit entries | `SettingService` | Giữ tối đa 20 entries, xóa least recently used khi vượt |
| 9 | Firestore rules | `firestore.rules` | `users/{userId}/quick_add_history/{docId}`: read/write if isCurrentUser |
| 10 | L10n keys | `app_vi.dart`, `app_en.dart` | +1 key: recentEntries |
