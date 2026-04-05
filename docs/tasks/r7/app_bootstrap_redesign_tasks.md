# Tasks: App Bootstrap Redesign

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Bootstrap models | `core/bootstrap/bootstrap_models.dart` | `BootstrapStep` enum (auth, account, settings, data, background). `BootstrapProgress` (step, current, total, label, done, error). `BootstrapResult` (needsLogin, needsAccountPick, locale) |
| 2 | BootstrapService | `core/bootstrap/bootstrap_service.dart` | `Stream<BootstrapProgress> run()` — chạy tuần tự auth → account → settings → data, yield progress mỗi step. Background step fire-and-forget. Timeout 8s/step, 30s tổng. Trả `BootstrapResult` ở step cuối |
| 3 | Auth step | `core/bootstrap/bootstrap_service.dart` | Check `currentUser`: null → `signInAnonymously()`, anonymous → giữ, logged-in → set userId. Fail → yield error, `needsLogin = true` |
| 4 | Account step | `core/bootstrap/bootstrap_service.dart` | Anonymous → `getOrCreatePersonalAccountId` + `_ensureDefaultWallet`. Logged-in → load `lastAccountId`, fallback `getOrCreatePersonalAccountId`. Nhiều account + không có lastAccountId → `needsAccountPick = true` |
| 5 | Settings step | `core/bootstrap/bootstrap_service.dart` | Load locale, lastWalletId. Fail → dùng defaults (vi, null). Graceful degradation |
| 6 | Data step | `core/bootstrap/bootstrap_service.dart` | Preload categories (dùng cho QuickAdd + filters). Fail → empty list, vẫn vào app |
| 7 | Background step | `core/bootstrap/bootstrap_service.dart` | Fire-and-forget: `QuickAddParser.init()`, `QuickAddHistory.init()`, `AmountHistory.init()`, `notificationService.init()`, `recurringService.checkAndRun()`, `reminderService.init()`, `ensureEmailIndex()` |
| 8 | SplashBootstrapScreen | `features/splash/splash_bootstrap_screen.dart` | Listen `BootstrapService.run()` stream. Hiển thị logo + `LinearProgressIndicator` (value = current/total) + step label. Khi done → navigate theo `BootstrapResult` (MainShell / AccountPicker / LoginScreen). Error → message + nút "Thử lại" |
| 9 | Simplify main.dart | `main.dart` | Bỏ toàn bộ `_init()`. `_buildHome()` trả `SplashBootstrapScreen`. Giữ locale callback + lifecycle observer |
| 10 | L10n keys | `app_vi.dart`, `app_en.dart` | Thêm: `bootstrapAuth` (Đang kết nối.../Connecting...), `bootstrapAccount` (Đang mở sổ.../Opening ledger...), `bootstrapSettings` (Đang tải cài đặt.../Loading settings...), `bootstrapData` (Đang tải danh mục.../Loading categories...), `bootstrapAlmost` (Sắp xong rồi.../Almost ready...) |
| 11 | Cleanup | `main.dart` | Xóa `_ensureDefaultWallet()` (chuyển vào BootstrapService). Xóa duplicate `QuickAddParser.init()` calls. Xóa các timeout rải rác |
