# Tasks: Quick Add Learning Persistence

> Quick Add ngày càng chính xác theo user. Keyword mappings persist qua sessions.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Persist learned map | Khi `QuickAddParser.learn()` được gọi, lưu mapping vào `users/{userId}/settings/prefs` field `quick_add_keywords` (Map<String, String>) | 🔴 |
| 2 | Load learned map on startup | Khi app init (sau auth), load `quick_add_keywords` từ Firestore → populate `QuickAddParser._learnedMap` | 🔴 |
| 3 | Refactor QuickAddParser | Thêm `static Future<void> init()` để load từ Firestore, và `static Future<void> _persist()` để save. `learn()` gọi `_persist()` | 🔴 |
| 4 | Debounce persist | Không persist mỗi lần learn — batch persist sau 5s idle hoặc khi app pause (WidgetsBindingObserver) | 🟡 |
| 5 | Clear learned keywords | Method `clearLearned()` + UI option trong Settings (nếu cần reset) | 🟢 |
| 6 | Max learned entries | Giới hạn 100 entries, xóa oldest khi vượt (LRU) | 🟢 |
