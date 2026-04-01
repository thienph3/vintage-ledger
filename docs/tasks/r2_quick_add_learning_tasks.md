# Tasks: Quick Add Learning Persistence

> Quick Add ngày càng chính xác theo user. Keyword mappings persist qua sessions.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Persist learned map | `learn()` → serialize map → lưu vào `users/{userId}/settings/prefs.quick_add_keywords` | ✅ |
| 2 | Load learned map on startup | `QuickAddParser.init()` gọi trong `main.dart _init()` sau auth → load từ Firestore → populate `_learnedMap` | ✅ |
| 3 | Refactor QuickAddParser | `init()` load, `learn()` schedule persist, `flush()` force persist, `clearLearned()` reset | ✅ |
| 4 | Debounce persist | Timer 5s sau lần learn cuối. `flush()` gọi khi app pause via WidgetsBindingObserver | ✅ |
| 5 | Clear learned keywords | `clearLearned()` + ListTile trong SettingScreen hiển thị count + tap to clear | ✅ |
| 6 | Max learned entries | LRU 100 entries — khi vượt, xóa oldest (first key) trước khi thêm mới | ✅ |
