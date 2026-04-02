# Vintage Ledger — Summary R6

> Ứng dụng quản lý thu chi cá nhân & gia đình, phong cách vintage, xây dựng bằng Flutter.
> 114 files Dart · ~10,900 LOC · 9 test files · 2 Cloud Function files (ready for Blaze)

---

## Thay đổi so với R5

| Hạng mục | R5 | R6 |
|---|---|---|
| Navigation | HomeScreen là root, settings icon trên AppBar | **MainShell + BottomNavigationBar** 4 tabs (Home, Transactions, Insights, Settings) |
| HomeScreen | Overloaded (chart, budget, streak, login prompt...) | **Simplified**: BalanceCard + WalletRow + InsightCard + CoachingCard + Recent Transactions + QuickAddBar |
| Transaction list | Group mode pills (day/week/month), infinite scroll | **Timeline Ledger**: month picker ◄►, day entries expand/collapse, vintage sổ tay style |
| Quick Add | Parse + keyword learning | **V2**: suggestion chips (top 5 by frequency), tap-to-submit, filter khi gõ, history persist |
| Recurring | Không có | **Recurring Transactions**: daily/weekly/monthly rules, atomic execution, toggle trong form, list screen |
| Reminder | Không có | **Daily Reminder**: local notification, configurable time, random messages, Settings toggle |
| Insights | Chart + budget trên Home | **InsightsTab** riêng: InsightCards (top category, weekly comparison, savings) + charts + budget |
| Coaching | Không có | **Smart Coaching**: rule-based tips theo lifecycle, dismissible, priority ordering |
| Invite | Share link (copy paste) | **Invite by email**: nhập email → lookup user_emails → pending_invites → accept/reject in-app |
| Firestore reads | N reads/session cho settings | **In-memory cache**: SettingService 1 read total, CategoryService cache-first, BudgetService cache-first, AccountService cache |
| Wallet rename | Phải vào form sửa | **Tap title** trên WalletDetailScreen → dialog rename |
| Compact format | 142900 → "142k" (truncated) | 142900 → **"142.9k"** (1 decimal) |
| SnackBar | Không auto-dismiss, mỗi chỗ tự quản | **showAppSnackBar** helper: clearSnackBars + duration 3s, theme showCloseIcon |
| Auth flow | Token chưa refresh sau login | **getIdToken(true)** force refresh sau login/register/link |
| Init | Có thể treo vô hạn | **try-catch + timeout** 5s cho settings, 10s cho auth, non-blocking init |
| Firestore rules | 10 match blocks, invites collection | **16 match blocks**: +pending_invites, +user_emails, +recurring_rules, fcm_tokens read mở cho authenticated, account update cho join |
| Indexes | 5 | **8**: +pending_invites (2), +recurring_rules (1) |
| Services | 9 | **11**: +RecurringService, +ReminderService |
| Dependencies | 11 | **13**: +flutter_local_notifications, +timezone |
| Files | 96 | **114** |
| LOC | ~8,900 | **~10,900** |
| L10n keys | ~200 | **~233** |

---

## Kiến trúc tổng quan

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Data**: Firestore-first — `FirestoreRepository<T>` base (CRUD + streams + atomic + ReadCounter + useCache option)
- **Offline**: Firestore persistence enabled, unlimited cache + in-memory cache layers
- **Auth**: Firebase Auth — anonymous auto → upgrade to email, getIdToken(true) force refresh
- **Balance**: Atomic via `firestore.runTransaction()`
- **Notifications**: Client-side FCM push + local notifications (daily reminder)
- **Error handling**: AppException + ErrorMapper → l10n messages
- **Caching**: SettingService (in-memory, 1 read), CategoryService (Firestore cache-first + background refresh), BudgetService (same), AccountService (in-memory per accountId)
- **DI**: ServiceLocator singleton (`sl`) — 11 services
- **L10n**: Vietnamese / English, ~233 keys
- **Navigation**: MainShell (BottomNavigationBar) → 4 tabs

---

## Tính năng mới R6

### 1. Home V2 — Simplified Dashboard
- **MainShell** với BottomNavigationBar: Home, Thu chi, Thống kê, Cài đặt
- HomeScreen rút gọn: BalanceCard → WalletRow → InsightCard → CoachingCard → Recent Transactions
- Charts, Budget, Streak chuyển sang InsightsTab
- Settings là tab riêng, không cần icon trên AppBar
- Đổi account: Settings → "Đổi sổ thu chi" thay vì swap_horiz trên Home

### 2. Quick Add V2 — Smart Suggestions
- `QuickAddHistory`: lưu entries (text, categoryId, amount, count, lastUsed)
- Suggestion chips hiện khi focus + text rỗng, filter khi gõ
- Tap chip → auto fill + submit ngay (1 tap = 1 transaction)
- Persist vào user settings, LRU limit 20 entries
- Debounced persist 3s + flush on app pause

### 3. Recurring Transactions
- `RecurringRule` model: amount, category, wallet, type, frequency (daily/weekly/monthly), nextRunAt, enabled
- `RecurringService`: CRUD + `checkAndRun()` atomic (runTransaction: create txn + update balance + advance nextRunAt)
- Toggle "Lặp lại" + frequency selector trong TransactionFormScreen
- RecurringListScreen: stream list, toggle enabled, swipe delete
- RecurringFormScreen: add/edit rule
- Auto-execute khi mở app (non-blocking)

### 4. Daily Reminder (Local Notification)
- `flutter_local_notifications` + `timezone`
- Schedule daily tại giờ user chọn (default 20:00)
- 4 random messages (l10n)
- Settings: SwitchListTile toggle + TimePicker
- Reschedule on app open if enabled
- Android: RECEIVE_BOOT_COMPLETED + SCHEDULE_EXACT_ALARM + POST_NOTIFICATIONS + boot receiver

### 5. Lightweight Insights
- `InsightService.generate()`: 3 insight types từ DashboardData
  - Top category: "Bạn chi nhiều nhất vào {category} ({amount})"
  - Weekly comparison: "Tuần này bạn chi nhiều/ít hơn {pct}%"
  - Savings: "Bạn đã tiết kiệm được {amount} 🎉"
- `InsightCard` widget: LedgerCard + icon + l10n resolved message
- InsightsTab: InsightCards trước charts + budget + streak
- HomeScreen: top insight highlight

### 6. Smart Coaching
- `CoachingService.getTip()`: rule-based, priority ordered
  1. No transactions → "Thử nhập 'ăn sáng 30k' 👇"
  2. Has txn, no budget → "Đặt ngân sách cho {topCategory}?" + action link
  3. Streak ≥ 3 → "Chi nhiều nhất vào {topCategory} ☕"
  4. Streak ≥ 7 → "Chi nhiều/ít hơn {pct}%"
- `CoachingCard`: dismissible (X), optional action button
- Dismiss tracking: persisted in user settings, không hiện lại
- 1 tip tại 1 thời điểm

### 7. Invite by Email (thay thế invite by link)
- Owner nhập email → lookup `user_emails/{email}` → tạo `pending_invites` doc
- Target user: AccountPickerScreen hiện banner accept/reject (StreamBuilder)
- FCM push notification đến target user
- Validation: userNotFound, cannotInviteSelf, alreadyMember, inviteAlreadySent
- `user_emails` collection: backfill on app open cho user cũ
- Batch write: `users` + `user_emails` atomic

### 8. Timeline Ledger (Transaction List V2)
- Month picker: ◄ Tháng 6, 2025 ► (tap arrows hoặc tap text → DatePicker)
- Day entries: số ngày (SpecialElite lớn) + thứ + số giao dịch + net amount
- Tap day → expand transactions bên dưới (indent 44px)
- Chỉ hiện ngày có transaction
- Bỏ: GroupMode pills, infinite scroll. Load 1 tháng tại 1 thời điểm

---

## Bug Fixes R6

| Bug | Root Cause | Fix |
|---|---|---|
| Tất cả ví đều có ngôi sao | `_resolveDefaultWallet([wallet])` luôn fallback về wallet đó | So sánh trực tiếp `wallet.id == _defaultWalletId` |
| SnackBar không auto-dismiss | Không có duration, SnackBar với action có thể persist | `showAppSnackBar` helper: clearSnackBars + duration 3s |
| Quick Add "✓ 0 Cà phê" | `_ctrl.clear()` trigger `_onChanged` reset amount trước khi save | Save amount trước clear (đã fix R5) |
| "Sửa thu chi" thay vì "Thêm" | QuickAddBar truyền `existing: prefill` → isEdit = true | Thêm param `prefill` tách biệt `existing` |
| Permission denied sau login | Firebase Auth token chưa refresh | `getIdToken(true)` sau login/register/link |
| Permission denied query wallet | `lastAccountId` null/stale → accountId rỗng | Persist `lastAccountId` ngay sau login + fallback resolve |
| Permission denied join family | `getAccount()` đọc account doc mà user chưa là member | Lưu `accountName` trong invite, bỏ `getAccount` trong join flow |
| Permission denied family detail | `/users/{userId}` chỉ cho isCurrentUser read | Mở read cho isAuthenticated |
| Permission denied invite email | Sender query `pending_invites` với `to_user_id != auth.uid` | Thêm `from_user_id` vào query + rule |
| FCM push fail đọc token user khác | `fcm_tokens` rule chỉ cho isCurrentUser | Mở read cho isAuthenticated |
| "Tài khoản không tồn tại" khi invite | `user_emails` chưa có cho user cũ | Fallback + `ensureEmailIndex` backfill on app open + batch write |
| App treo loading vô hạn | `_init()` không có try-catch, Firestore timeout | try-catch toàn bộ + timeout 5s/10s |
| family_detail_screen syntax error | Replace merge nhầm closing braces | Khôi phục `_removeMember` + `_leave` methods |
| Wallet card bottom overflow | Số tiền dài tràn card 150x90 | `compact: true` cho AmountText |
| Compact format truncate | `_compactVi` dùng integer division | Double division + `toStringAsFixed(1)` |
| TransactionListScreen mất back button | `showBackButton: widget.walletId != null` | Thêm `isTab` param |
| `flutter_local_notifications` build fail | Cần core library desugaring | `isCoreLibraryDesugaringEnabled = true` + desugar_jdk_libs |

---

## Firestore Schema

```
accounts/{accountId}/
  ├── wallets/{docId}              → name, balance, currency, created_at, updated_at
  ├── transactions/{docId}         → wallet_id, category_id, type, amount, note, date, created_by, items[], created_at, updated_at
  ├── categories/{docId}           → name, type, icon, created_at, updated_at
  ├── budgets/{docId}              → category_id, amount_limit, period, created_at, updated_at
  ├── recurring_rules/{docId}      → amount, category_id, wallet_id, type, frequency, note, next_run_at, enabled, created_at, updated_at
  ├── activities/{docId}           → user_id, action, description, created_at
  └── notification_events/{eventId} → created_at

users/{userId}/
  ├── email, display_name, account_ids[], created_at
  ├── settings/prefs → locale, default_currency, last_account_id, last_wallet_id, quick_add_keywords, quick_add_history, streak_*, reminder_*, dismissed_tips
  └── fcm_tokens/{token} → token, updated_at

pending_invites/{inviteId}/ → account_id, account_name, from_user_id, to_user_id, to_email, status, created_at
user_emails/{email}         → user_id
config/fcm                  → server_key
```

### Security Rules (16 match blocks)

| Path | Read | Write |
|---|---|---|
| `users/{userId}` | isAuthenticated | isCurrentUser |
| `users/{userId}/settings/**` | isCurrentUser | isCurrentUser |
| `users/{userId}/fcm_tokens/**` | isAuthenticated | isCurrentUser |
| `accounts/{accountId}` | isMember | create: uid in members. update: isOwner OR self-join. delete: isOwner |
| `.../wallets` | isMember | isMember (name required) |
| `.../transactions` | isMember | isMember (amount > 0, type valid) |
| `.../categories` | isMember | isMember (name required) |
| `.../budgets` | isMember | isMember (amount_limit > 0) |
| `.../recurring_rules` | isMember | isMember (amount > 0) |
| `.../activities` | isMember | create: isMember + user_id == uid |
| `.../notification_events` | isMember | create/delete: isMember |
| `pending_invites/{id}` | to_user OR from_user | create: from_user == uid. update: to_user + status only |
| `user_emails/{email}` | isAuthenticated | user_id == uid |
| `config/{docId}` | isAuthenticated | deny |

### Composite Indexes (8)

| Collection | Fields |
|---|---|
| transactions | wallet_id + date DESC |
| transactions | wallet_id + date ASC |
| categories | type + name ASC |
| transactions | category_id + type + date ASC |
| transactions | type + date ASC |
| pending_invites | to_user_id + status |
| pending_invites | from_user_id + account_id + to_user_id + status |
| recurring_rules | enabled + next_run_at ASC |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | Cloud Firestore (offline persistence + in-memory cache layers) |
| Auth | Firebase Auth (anonymous + email + link + force token refresh) |
| Notifications | Firebase Messaging (client-side FCM) + flutter_local_notifications (daily reminder) |
| Charts | fl_chart |
| Export | share_plus + path_provider |
| Fonts | SpecialElite, PatrickHand (bundled) |
| Swipe | flutter_slidable |
| L10n | flutter_localizations + custom S helper |
| Timezone | timezone (for scheduled notifications) |

---

## Project Structure

```
lib/                              # 114 files, ~10,900 LOC
├── core/
│   ├── constants/                # category_icons, currency, seed_categories
│   ├── debug/                    # ReadCounter
│   ├── enums/                    # transaction_type
│   ├── firestore/                # FirestoreRepository<T> (+useCache)
│   ├── l10n/                     # vi (~233 keys), en (~233 keys), S helper
│   ├── theme/                    # AppColors, AppTextStyles, AppSpacing, AppTheme
│   ├── app_exception.dart
│   ├── app_state.dart
│   ├── error_mapper.dart
│   └── service_locator.dart      # 11 services
├── common/widgets/               # ~20 widgets (app_snackbar, app_scaffold+onTitleTap, ...)
├── features/
│   ├── account/                  # Account, AccountService (+cache, +email invite, +batch write), 4 screens
│   ├── auth/                     # AuthService (+getIdToken force refresh), 2 screens
│   ├── budget/                   # Budget, BudgetService (+cache), 3 screens
│   ├── category/                 # Category, CategoryService (+Firestore cache-first), 2 screens
│   ├── coaching/                 # CoachingService, CoachingTip, CoachingCard (NEW)
│   ├── export/                   # ExportService (CSV)
│   ├── home/                     # HomeScreen (simplified V2)
│   ├── insights/                 # InsightService, InsightCard, InsightsTab (NEW)
│   ├── main_shell.dart           # BottomNavigationBar 4 tabs (NEW)
│   ├── notification/             # NotificationService (FCM)
│   ├── quick_add/                # QuickAddParser, QuickAddBar, QuickAddHistory (+suggestions) (NEW)
│   ├── recurring/                # RecurringRule, RecurringService, 2 screens (NEW)
│   ├── reminder/                 # ReminderService (local notifications) (NEW)
│   ├── settings/                 # SettingService (+in-memory cache), SettingScreen (+recurring, +reminder, +switch account)
│   ├── transaction/              # Atomic CRUD, Timeline Ledger (V2), TransactionFormScreen (+prefill, +recurring toggle)
│   └── wallet/                   # WalletService (+renameWallet), WalletDetailScreen (+tap title rename)
├── utils/                        # AmountFormatter (fixed compact), DateFormatter (+dayOfWeek, +monthYearLong)
└── main.dart                     # try-catch init, timeout, non-blocking services
```

---

## Evolution Summary

| Round | Focus | Files | LOC | L10n | Services | Rules | Indexes |
|---|---|---|---|---|---|---|---|
| R1 | SQLite + manual sync | 78 | ~7,600 | ~120 | 6 | — | — |
| R2 | Firestore-first + features | 91 | ~7,650 | ~160 | 7 | 7 | 3 |
| R3 | Production hardening | 95 | ~8,200 | ~180 | 8 | 10 | 5 |
| R4 | Polish | 95 | ~8,600 | ~190 | 9 | 10 | 5 |
| R5 | Trust & UX | 96 | ~8,900 | ~200 | 9 | 10 | 5 |
| R6 | Engagement & Structure | 114 | ~10,900 | ~233 | 11 | 16 | 8 |
