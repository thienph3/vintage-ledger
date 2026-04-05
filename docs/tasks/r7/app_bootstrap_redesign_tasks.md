# Tasks: App Bootstrap Redesign

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | Bootstrap models | `core/bootstrap/bootstrap_models.dart` | `BootstrapStep` enum (auth, account, settings, data, background). `BootstrapProgress` (step, current, total, label, done, error). `BootstrapResult` (needsLogin, needsAccountPick, locale) |
| 2 | AppCache singleton | `core/app_cache.dart` | Chứa: `categories`, `categoryNameMap`, `currentAccount`, `memberProfiles`, `lastWalletId`. Expose qua `sl.cache`. Có `invalidate()` method để clear từng entry |
| 3 | BootstrapService — auth step | `core/bootstrap/bootstrap_service.dart` | Check `currentUser`: null → `signInAnonymously()`, anonymous → giữ, logged-in → set userId. Fail → yield error, `needsLogin = true` |
| 4 | BootstrapService — account step | `core/bootstrap/bootstrap_service.dart` | Anonymous → `getOrCreatePersonalAccountId` + ensure default wallet. Logged-in → load `lastAccountId`, fallback `getOrCreatePersonalAccountId`. Nhiều account + không có lastAccountId → `needsAccountPick = true` |
| 5 | BootstrapService — settings step | `core/bootstrap/bootstrap_service.dart` | Load locale, lastWalletId → lưu vào `AppCache`. Fail → dùng defaults (vi, null) |
| 6 | BootstrapService — data step | `core/bootstrap/bootstrap_service.dart` | `Future.wait` load song song: categories, account info, member profiles. Populate `AppCache` + `FeedHelper.preloadNames(memberIds)`. Fail → empty defaults, vẫn vào app |
| 7 | BootstrapService — background step | `core/bootstrap/bootstrap_service.dart` | Fire-and-forget: `QuickAddParser.init()`, `QuickAddHistory.init()`, `AmountHistory.init()`, `notificationService.init()`, `recurringService.checkAndRun()`, `reminderService.init()`, `ensureEmailIndex()` |
| 8 | SplashBootstrapScreen | `features/splash/splash_bootstrap_screen.dart` | Listen `BootstrapService.run()` stream. Logo + `LinearProgressIndicator` (value = current/total) + step label. Done → navigate theo `BootstrapResult`. Error → message + nút "Thử lại" |
| 9 | Simplify main.dart | `main.dart` | Bỏ toàn bộ `_init()`. `_buildHome()` trả `SplashBootstrapScreen`. Giữ locale callback + lifecycle observer |
| 10 | Migrate HomeScreen | `home_screen.dart` | Bỏ `_load()` fetch categories/account/lastWalletId. Đọc từ `sl.cache`. Giữ `StreamBuilder` cho wallets + today txns |
| 11 | Migrate TransactionListScreen | `transaction_list_screen.dart` | Bỏ `_initialLoad()` fetch categories/wallets/account/members. Đọc từ `sl.cache`. Chỉ giữ `_loadRange()` cho txn data |
| 12 | Migrate QuickAddBar | `quick_add_bar.dart` | Bỏ `_loadCategories()`. Đọc `sl.cache.categories` |
| 13 | L10n keys | `app_vi.dart`, `app_en.dart` | Thêm: `bootstrapAuth` (Đang kết nối.../Connecting...), `bootstrapAccount` (Đang mở sổ.../Opening ledger...), `bootstrapSettings` (Đang tải cài đặt.../Loading settings...), `bootstrapData` (Đang chuẩn bị.../Getting ready...), `bootstrapAlmost` (Sắp xong rồi.../Almost ready...) |
| 14 | Cleanup | `main.dart` | Xóa `_ensureDefaultWallet()` (chuyển vào BootstrapService). Xóa duplicate init calls. Xóa timeout rải rác |
