# Vintage Ledger — Summary R4

> Ứng dụng quản lý thu chi cá nhân & gia đình, phong cách vintage, xây dựng bằng Flutter.
> 95 files Dart · ~8,600 LOC · 10 test files · 2 Cloud Function files (ready for Blaze)

---

## Thay đổi so với R3

| Hạng mục | R3 | R4 |
|---|---|---|
| Firestore indexes | 3 composite | 5 composite (+budget queries) |
| Balance tests | Chưa có | 8 unit tests cover tất cả edge cases |
| FCM reliability | Basic push | Deduplication (TTL 60s) + retry 2x backoff + stale token cleanup + duplicate token prevention + debug logging |
| Notification UX | Raw messages | Rich messages + anti-spam debounce 2s + categoryName |
| Activity feed | Raw description | Rich messages + user name + visual hierarchy (bold others) + relative timestamps |
| Activity coverage | Chỉ transactions | +wallet create/delete, join/leave family |
| Quick Add UX | Save trực tiếp | Undo snackbar 4s + fuzzy → fallback to full form |
| Category reads | Mỗi lần query Firestore | In-memory cache, invalidate on write |
| Read tracking | Total count only | Per-screen breakdown + stream reads counted |
| HomeScreen streams | 2 wallet StreamBuilders | 1 merged stream |
| Onboarding prompt | ≥3 transactions | Smart: ≥5 txns OR ≥3 days |
| Family onboarding | Chỉ "Tạo gia đình" | +promo text + "Tham gia bằng link" + join dialog |
| Success feedback | Không có | Savings highlight + monthly comparison + streak counter |
| LOC | ~8,200 | ~8,600 |
| Test files | 8 | 10 |

---

## Kiến trúc tổng quan

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Data**: Firestore-first — `FirestoreRepository<T>` base (CRUD + streams + atomic helpers + ReadCounter hooks)
- **Offline**: Firestore persistence enabled, unlimited cache
- **Auth**: Firebase Auth — anonymous auto → upgrade to email via linkWithEmail
- **Balance**: Atomic via `firestore.runTransaction()` — tested 8 edge cases
- **Notifications**: Client-side FCM push (legacy HTTP API) — server key from Firestore `config/fcm`, dedup + retry + stale cleanup
- **Error handling**: AppException + ErrorMapper → l10n messages + retry snackbar
- **Caching**: Category in-memory cache, Quick Add keywords persisted + LRU
- **DI**: ServiceLocator singleton (`sl`) — 9 services
- **State**: AppState (currentUserId, currentAccountId, hasAccount)
- **L10n**: Vietnamese (mặc định) / English, ~190 keys
- **Theme**: Vintage — SpecialElite + PatrickHand, paper background, ink colors

---

## Tính năng chi tiết

### 1. Xác thực (Auth)

| Tính năng | Mô tả |
|---|---|
| Anonymous auto sign-in | Mở app → dùng ngay |
| Đăng nhập / Đăng ký | Email + password, user-friendly error messages |
| Upgrade anonymous | linkWithEmail, giữ data |
| Đăng xuất | Remove FCM token → sign out |
| Smart login prompt | Hiển thị sau ≥5 transactions HOẶC ≥3 ngày sử dụng |

### 2. Hệ thống Account

| Tính năng | Mô tả |
|---|---|
| Personal + Family | Unified schema `accounts/{accountId}/` |
| Auto-create | Personal account + "Ví chính" cho anonymous lần đầu |
| Persist context | lastAccountId + lastWalletId, restore on startup |
| Skip AccountPicker | Nếu đã có lastAccountId → Home luôn |

### 3. Quản lý gia đình (Family V2)

| Tính năng | Mô tả |
|---|---|
| Tạo gia đình | Seed categories + "Ví chung" mặc định |
| Invite bằng link | Token 7 ngày, copy link, FCM notification |
| Join by link | Dialog paste link → extract tokenId → JoinFamilyScreen |
| Family promo | "Chia sẻ chi tiêu với người thân 👨‍👩‍👧" khi chỉ có 1 account |
| Member management | Remove, leave, transfer ownership |
| Member avatars | CircleAvatar initials, owner màu inkBlue |
| Activity feed V2 | Rich messages ("{user} đã chi 50k"), bold others, relative time, log wallet/join/leave |
| Created by | Icon people_outline cho transactions tạo bởi member khác |

### 4. Quản lý ví (Wallet)

| Tính năng | Mô tả |
|---|---|
| CRUD | Tạo (tên + số dư + currency), sửa, xóa |
| Multi-currency | 8 currencies (VND, USD, EUR, GBP, JPY, KRW, CNY, THB) |
| Realtime | StreamBuilder |
| Balance atomic | `runTransaction` — tested 8 edge cases |
| Recalculate | Tool cho fix data inconsistent |
| Activity log | Log tạo/xóa ví vào activity feed |

### 5. Quản lý giao dịch (Transaction)

| Tính năng | Mô tả |
|---|---|
| Atomic CRUD | create/update/delete đều dùng `runTransaction` |
| Update edge cases | Change amount, type, wallet, combined — tất cả tested |
| Auto-select wallet | Last used từ settings |
| Budget alert | Warning khi category gần/vượt budget |
| Lazy loading | getByDateRange() trực tiếp per month |
| FCM notification | Gửi đến family members, debounce 2s |
| Activity log | Rich messages trong activity feed |

### 6. Quick Add

| Tính năng | Mô tả |
|---|---|
| QuickAddBar | Bottom bar, parse 1 dòng |
| Amount parsing | "50k", "10tr", "1.5tr", "2 tỷ" |
| Category matching | 30+ keywords vi/en, learned (persisted + LRU 100) |
| Confidence | Fuzzy match → fallback to full form |
| Undo | Snackbar 4s "✓ 50k Ăn uống" + "Hoàn tác" → delete + reload |
| Clear learned | Option trong Settings |

### 7. Ngân sách & Insight (Budget)

| Tính năng | Mô tả |
|---|---|
| Budget per category | Monthly limit, upsert, optimized queries (không qua getDashboard) |
| Progress UI | Xanh < 80%, vàng 80-100%, đỏ > 100% |
| Budget summary | Card trên Home |
| Budget alert | Warning trong TransactionFormScreen |
| Monthly insight | Summary + highlight ("Tiết kiệm được X 🎉" / "Chi nhiều hơn X") + top spending + vs last month bars |
| Premium gate | PremiumGate.isUnlocked placeholder |

### 8. Notifications (FCM)

| Tính năng | Mô tả |
|---|---|
| Token registration | Auto register + refresh + cleanup duplicates |
| Client-side push | Legacy HTTP API, server key from Firestore `config/fcm` |
| Deduplication | Event ID + TTL 60s in-memory set |
| Retry | Max 2x, delay 500ms → 1s, timeout 10s |
| Stale token cleanup | Parse FCM response, remove InvalidRegistration/NotRegistered |
| Rich messages | Invite: "Bạn được mời vào gia đình {name}". Transaction: "Giao dịch mới: chi {amount} {category}" |
| Anti-spam | Debounce 2s, batch rapid transactions |
| Tap navigation | invite → JoinFamilyScreen, transaction → HomeScreen |
| Debug logging | `debugPrint` chỉ trong kDebugMode |
| Cloud Functions ready | `functions/index.js` cho Blaze plan |

### 9. Biểu đồ (Charts)

| Tính năng | Mô tả |
|---|---|
| 4 views | Trend / Daily / Breakdown / Summary với animated switch |

### 10. Màn hình chính (Home)

| Tính năng | Mô tả |
|---|---|
| Balance card | Tổng số dư, ẩn/hiện, mixed currencies (merged stream — 1 StreamBuilder) |
| Wallet row | Horizontal scroll + currency per wallet |
| Chart section | Biểu đồ tháng |
| Budget summary | Cảnh báo budgets gần/vượt limit |
| Savings highlight | "🎉 Tháng này bạn tiết kiệm được 500k" (khi net > 0) |
| Streak | "🔥 5 ngày liên tiếp" (khi streak ≥ 2) |
| Login prompt | Smart trigger cho anonymous users |
| QuickAddBar | Bottom bar (hoặc first-run hint) |
| Network banner | Offline indicator |

### 11. Cài đặt (Settings)

| Tính năng | Mô tả |
|---|---|
| Account info | Email/name hoặc register prompt |
| Default currency | 8 currencies picker |
| Ngôn ngữ | Vi / En runtime switch |
| Clear learned keywords | Count + tap to clear |
| Firestore reads debug | Total + per-screen breakdown + reset |

### 12. Error Handling

| Tính năng | Mô tả |
|---|---|
| AppException + ErrorMapper | Firestore + Auth errors → l10n keys |
| showErrorSnackBar | Mapped message + optional retry |
| Auth screens | User-friendly error messages |

### 13. Multi-Currency

| Tính năng | Mô tả |
|---|---|
| 8 currencies | VND, USD, EUR, GBP, JPY, KRW, CNY, THB |
| Format | Full + compact, symbol position, decimals |
| Mixed currencies | "Nhiều loại tiền" trên Home |

### 14. Success Feedback

| Tính năng | Mô tả |
|---|---|
| Monthly highlight | "Tiết kiệm được X 🎉" hoặc "Chi nhiều hơn X" trong MonthlyInsightScreen |
| Home savings card | Khi net > 0 |
| Streak counter | Track daily usage, hiển thị "🔥 N ngày liên tiếp" |

---

## Firestore Schema

```
accounts/{accountId}/
  ├── wallets/{docId}       → name, balance, currency, created_at, updated_at
  ├── transactions/{docId}  → wallet_id, category_id, type, amount, note, date, created_by, items[], created_at, updated_at
  ├── categories/{docId}    → name, type, icon, created_at, updated_at
  ├── budgets/{docId}       → category_id, amount_limit, period, created_at, updated_at
  └── activities/{docId}    → user_id, action, description, created_at

users/{userId}/
  ├── email, display_name, account_ids[], created_at
  ├── settings/prefs        → locale, default_currency, last_account_id, last_wallet_id, quick_add_keywords, streak_last_date, streak_count
  └── fcm_tokens/{token}    → token, updated_at

invites/{tokenId}/          → account_id, created_by, created_at, expires_at
config/fcm                  → server_key (read-only)
```

### Security Rules

| Path | Read | Write | Validation |
|---|---|---|---|
| `users/{userId}/**` | isCurrentUser | isCurrentUser | — |
| `accounts/{accountId}` | isMember | create: uid in member_ids. update/delete: isOwner | — |
| `.../wallets` | isMember | isMember | name.size() > 0 |
| `.../transactions` | isMember | isMember | amount > 0, type in [income, expense] |
| `.../categories` | isMember | isMember | name.size() > 0 |
| `.../budgets` | isMember | isMember | amount_limit > 0 |
| `.../activities` | isMember | create: isMember + user_id == uid. update/delete: deny | — |
| `invites/{tokenId}` | authenticated | create: isMember of account. update/delete: deny | — |
| `config/{docId}` | authenticated | deny | — |

### Composite Indexes (5)

| Collection | Fields | Query |
|---|---|---|
| transactions | wallet_id + date DESC | Recent by wallet |
| transactions | wallet_id + date ASC | Date range by wallet |
| categories | type + name ASC | Categories by type |
| transactions | category_id + type + date ASC | checkBudget per category |
| transactions | type + date ASC | getBudgetStatuses monthly expense |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | Cloud Firestore (offline persistence, unlimited cache) |
| Auth | Firebase Auth (anonymous + email/password + link) |
| Notifications | Firebase Messaging + http (client-side FCM legacy API) |
| Charts | fl_chart |
| Fonts | SpecialElite, PatrickHand (bundled) |
| Swipe actions | flutter_slidable |
| L10n | flutter_localizations + custom S helper |

---

## Project Structure

```
lib/                          # 95 files, ~8,600 LOC
├── core/
│   ├── constants/            # category_icons, currency (8)
│   ├── debug/                # ReadCounter (per-screen + streams)
│   ├── enums/                # transaction_type
│   ├── firestore/            # FirestoreRepository<T> (CRUD + streams + atomic + ReadCounter)
│   ├── l10n/                 # vi (~190 keys), en (~190 keys), S helper
│   ├── theme/                # AppColors, AppTextStyles, AppSpacing, AppTheme
│   ├── app_exception.dart
│   ├── app_state.dart
│   ├── error_mapper.dart     # Firestore + Auth → AppException
│   ├── premium_gate.dart
│   └── service_locator.dart  # 9 services
├── common/widgets/           # 19 widgets (incl. error_snackbar, login_prompt_card, network_status_banner)
├── features/
│   ├── account/              # Account, InviteToken, AccountService (+activity log join/leave), 4 screens (incl. join by link)
│   ├── auth/                 # AuthService (error mapping), 2 screens
│   ├── budget/               # Budget, BudgetStatus, optimized queries, 3 screens, 2 widgets, monthly highlight
│   ├── category/             # Category, in-memory cache, 2 screens
│   ├── home/                 # HomeScreen (merged stream, savings highlight, streak, smart prompt)
│   ├── notification/         # NotificationService (dedup, retry, stale cleanup, debounce, rich messages)
│   ├── quick_add/            # QuickAddParser (persist, LRU, fuzzy flag), QuickAddBar (undo, confidence fallback)
│   ├── settings/             # SettingService (+streak), SettingScreen (debug reads breakdown)
│   ├── transaction/          # Atomic CRUD (8 edge cases tested), lazy loading, 2 screens, charts/, widgets/
│   └── wallet/               # Wallet (+activity log), recalculate, 3 screens
├── utils/                    # AmountFormatter (multi-currency), DateFormatter (+relative), NavigatorX
└── main.dart                 # Firebase init, anonymous auth, lifecycle observer, notification init

test/                         # 10 test files
├── core/                     # error_mapper_test, transaction_type_test
├── models/                   # models_test
├── quick_add/                # quick_add_parser_test
├── sync/                     # upsert_test (legacy)
├── transaction/              # atomic_balance_test (8 cases)
└── utils/                    # amount_formatter_test, date_formatter_test, currency_formatter_test

functions/                    # Cloud Functions (ready for Blaze)
├── index.js                  # onInviteCreated, onTransactionCreated
└── package.json

docs/
├── summary_r4.md             # This file
├── tests/                    # offline_consistency_checklist.md
├── features/r3/              # 12 feature specs
└── tasks/r3/                 # 12 task files (53/56 completed)
```

---

## Known Issues

1. **Client-side FCM push (security)** — Server key in Firestore `config/fcm`, readable by authenticated users. Migrate to Cloud Functions on Blaze plan. `functions/index.js` ready.

2. **fcm_tokens read access** — NotificationService reads other users' `fcm_tokens/`. Security rules restrict to isCurrentUser → client-side push may fail for other users' tokens. Workaround: mở rộng rules cho members cùng account, hoặc chuyển Cloud Functions.

3. **Test coverage** — 10 test files cover utils, models, parser, balance logic, error mapper. Không có widget tests hoặc integration tests với Firestore emulator.

4. **Currency conversion** — Mixed currencies không thể tính tổng balance. Cần exchange rate API.

5. **Concurrent transaction test** — `runTransaction` handles conflicts, nhưng chưa test trên 2 devices thật.

6. **Deploy pending** — `firebase deploy --only firestore:indexes,firestore:rules` cần chạy thủ công.

---

## Evolution Summary

| Round | Focus | Files | LOC |
|---|---|---|---|
| R1 | SQLite + manual sync | 78 | ~7,600 |
| R2 | Firestore-first + new features (Quick Add, Budget, Currency, Family V2, Onboarding) | 91 | ~7,650 |
| R3 | Production hardening (atomic balance, security rules, indexes, error handling, notifications, query optimization) | 95 | ~8,200 |
| R4 | Polish (FCM reliability, notification UX, activity feed V2, Quick Add undo, read optimization, onboarding clarity, family onboarding, success feedback, streak, category cache) | 95 | ~8,600 |
