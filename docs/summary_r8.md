# Vintage Ledger — Summary R8

> Ứng dụng quản lý thu chi cho couples, phong cách modern soft journal, xây dựng bằng Flutter.
> 124 files Dart · ~12,400 LOC · 12 services

---

## Thay đổi so với R7

| Hạng mục | R7 | R8 |
|---|---|---|
| App startup | `CircularProgressIndicator` quay mòng mòng, logic monolithic trong `_init()` | **SplashBootstrapScreen** — 5-step pipeline với progress bar + step label |
| Data loading | Mỗi screen tự fetch (categories, account, members) → duplicate reads | **AppCache** singleton — bootstrap preload 1 lần, screens đọc từ cache |
| Member names | HomeScreen hiện "?" vì FeedHelper chưa preload | **Fixed** — bootstrap data step gọi `FeedHelper.preloadNames(memberIds)` |
| Auth transitions | Race condition: streams active sau logout → "không có quyền truy cập" | **Tất cả auth transitions đi qua SplashBootstrapScreen** — clear state → navigate → bootstrap pipeline |
| Anonymous → Login | Logic rải rác ở LoginScreen + SettingScreen, migrate inline | **LoginIntent** — SettingScreen chỉ clear + navigate, bootstrap xử lý logout → sign-in → migrate → delete anon |
| Account persistence | Luôn vào personal account khi mở app | **lastAccountId** — bootstrap check sổ cuối cùng, verify membership, fallback personal |
| Account switching | AccountPicker → MainShell (cache cũ) | AccountPicker → **SplashBootstrapScreen** → MainShell (cache reload) |
| Transaction list | Chỉ có list theo tháng | **3 time range modes** (ngày/tuần/tháng) + **2 view modes** (list/calendar) |
| Calendar view | Không có | **CalendarGrid** — expense mỗi ngày, tap xem detail |
| MainShell | Không có initialTab | **initialTab** param — bootstrap redirect đúng tab sau login |
| Files | 121 | **124** |
| LOC | ~11,700 | **~12,400** |
| L10n keys | ~248 | **~258** |

---

## New Features R8

### 1. App Bootstrap Pipeline

5-step pipeline chạy tuần tự trên `SplashBootstrapScreen`:

| Step | Label (vi) | Công việc |
|------|-----------|-----------|
| auth | Đang kết nối... | Check/create Firebase auth, hoặc logout → sign-in nếu có `LoginIntent` |
| account | Đang mở sổ... | Resolve account (check `lastAccountId` → verify membership → fallback personal), migrate anon data |
| settings | Đang tải cài đặt... | Load locale, lastWalletId → `AppCache` |
| data | Đang chuẩn bị... | Parallel load categories + account info + member profiles → `AppCache` + `FeedHelper` |
| background | Sắp xong rồi... | Fire-and-forget: QuickAdd caches, notifications, recurring, reminders |

UI: Logo + `LinearProgressIndicator` (determinate) + step label. Error → message + nút "Thử lại".

### 2. AppCache Singleton

```dart
class AppCache {
  List<Category> categories;
  Map<String, String> categoryNameMap;
  Account? currentAccount;
  List<Map<String, String>> memberProfiles;
  String? lastWalletId;
}
```

- Exposed qua `sl.cache`
- Bootstrap populate 1 lần, screens đọc trực tiếp (không fetch riêng)
- Loại bỏ 5+ duplicate Firestore reads mỗi lần chuyển tab

### 3. LoginIntent — Auth Transitions Qua Bootstrap

```dart
class LoginIntent {
  final LoginMethod method;       // google | email
  final String? anonAccountIdToMigrate;
  final int? returnToTab;
  final String? email, password;
}
```

Flow khi anonymous → Google sign-in từ SettingScreen:
1. `_resetAndBootstrap()` — clear appState/cache/FeedHelper (kill streams)
2. Navigate `SplashBootstrapScreen(loginIntent: LoginIntent(google, anonId, returnToTab: 3))`
3. Bootstrap: logout → Google sign-in → resolve account → migrate anon → preload data
4. Navigate `MainShell(initialTab: 3)` → user quay lại SettingScreen

### 4. Transaction List Redesign

**Time Range Mode** — 3 chip (Ngày / Tuần / Tháng):
- Ngày: flat list, range picker `Thứ Hai, 14/07`
- Tuần: day-group, range picker `08/07 – 14/07`
- Tháng: day-group expand/collapse (giữ nguyên)

**View Mode** — toggle list/calendar (chỉ ở Tháng):
- List: day-group expand/collapse
- Calendar: grid 7 cột, expense compact mỗi ô (`-80k`), tap → detail bên dưới

**CalendarGrid widget**: today highlight, selected accent, empty state per day.

### 5. Remember Last Account

- Bootstrap `_runAccount()` check `lastAccountId` trước cho logged-in user
- Verify account tồn tại + user vẫn là member
- Fallback personal nếu invalid (bị kick, account bị xóa)
- AccountPickerScreen → SplashBootstrapScreen (reload cache cho account mới)

---

## Bug Fixes R8

| Bug | Root Cause | Fix |
|---|---|---|
| Member names hiện "?" trên HomeScreen | `FeedHelper._nameCache` trống, HomeScreen không gọi `preloadNames()` | Bootstrap data step preload member profiles |
| "Không có quyền truy cập" khi login | Firestore streams active sau logout, auth token null → `isMember()` fail | Clear state + navigate away (kill streams) trước logout |
| Luôn vào personal account | `_runAccount()` bỏ qua `lastAccountId`, luôn resolve personal | Check `lastAccountId` trước, verify membership |
| Cache cũ sau đổi sổ | AccountPicker → MainShell trực tiếp | AccountPicker → SplashBootstrapScreen → MainShell |
| Duplicate Firestore reads | 5+ screens mỗi cái gọi `getCategories()` riêng | AppCache preload 1 lần |

---

## Architecture

```
SplashBootstrapScreen (5-step pipeline)
  ├── LoginIntent? → logout → sign-in → migrate
  ├── Populate AppCache (categories, account, members, lastWalletId)
  ├── FeedHelper.preloadNames()
  └── Navigate → MainShell(initialTab) | LoginScreen | AccountPicker

MainShell (BottomNavigationBar, initialTab)
├── Home tab — Today Total + Shared Feed (StreamBuilder) + QuickAddBar
│   └── Reads: sl.cache (categories, account name, lastWalletId)
├── Transactions tab — Time Range + View Mode + Filters + QuickAddBar
│   └── Reads: sl.cache (categories, members), fetches: wallets + txn data
├── Insights tab — InsightCards + Charts + Budget + Streak
└── Settings tab — Profile card + Manage + Preferences
    └── Auth actions → _resetAndBootstrap(LoginIntent) → SplashBootstrapScreen
```

### Data Flow
```
BootstrapService.run() → Stream<BootstrapProgress>
  ├── _runAuth()     → sl.appState.currentUserId
  ├── _runAccount()  → sl.appState.currentAccountId (from lastAccountId or resolve)
  ├── _runSettings() → sl.cache.lastWalletId
  ├── _runData()     → sl.cache.categories, .currentAccount, .memberProfiles
  └── _runBackground() → fire-and-forget (QuickAdd, notifications, recurring)
```

---

## Project Structure (changes)

```
lib/
├── core/
│   ├── bootstrap/
│   │   ├── bootstrap_models.dart   # NEW — BootstrapStep, LoginIntent, BootstrapProgress, BootstrapResult
│   │   └── bootstrap_service.dart  # NEW — 5-step pipeline with LoginIntent support
│   ├── app_cache.dart              # NEW — AppCache singleton (categories, account, members)
│   └── service_locator.dart        # CHANGED — added cache = AppCache()
├── features/
│   ├── splash/
│   │   └── splash_bootstrap_screen.dart  # NEW — progressive loading UI
│   ├── transaction/
│   │   ├── screens/
│   │   │   └── transaction_list_screen.dart  # CHANGED — TimeRangeMode, ViewMode, calendar
│   │   └── widgets/
│   │       └── calendar_grid.dart            # NEW — month calendar with daily expense
│   ├── main_shell.dart             # CHANGED — initialTab param
│   ├── auth/screens/login_screen.dart    # CHANGED — delegates to SplashBootstrapScreen
│   ├── account/screens/account_picker_screen.dart  # CHANGED — navigate via SplashBootstrapScreen
│   ├── home/screens/home_screen.dart     # CHANGED — reads from sl.cache
│   ├── quick_add/quick_add_bar.dart      # CHANGED — reads from sl.cache
│   └── settings/screens/setting_screen.dart  # CHANGED — _resetAndBootstrap(LoginIntent)
├── main.dart                       # CHANGED — simplified, home = SplashBootstrapScreen
└── core/l10n/
    ├── app_vi.dart                 # CHANGED — +10 keys (bootstrap + view modes)
    └── app_en.dart                 # CHANGED — +10 keys
```

---

## Evolution Summary

| Round | Focus | Files | LOC | L10n | Services |
|---|---|---|---|---|---|
| R1 | SQLite + manual sync | 78 | ~7,600 | ~120 | 6 |
| R2 | Firestore-first + features | 91 | ~7,650 | ~160 | 7 |
| R3 | Production hardening | 95 | ~8,200 | ~180 | 8 |
| R4 | Polish | 95 | ~8,600 | ~190 | 9 |
| R5 | Trust & UX | 96 | ~8,900 | ~200 | 9 |
| R6 | Engagement & Structure | 114 | ~10,900 | ~233 | 11 |
| R7 | Style Guide Migration | 121 | ~11,700 | ~248 | 12 |
| R8 | **Bootstrap + Auth + Calendar** | **124** | **~12,400** | **~258** | **12** |
