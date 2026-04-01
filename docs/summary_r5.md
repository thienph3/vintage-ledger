# Vintage Ledger — Summary R5

> Ứng dụng quản lý thu chi cá nhân & gia đình, phong cách vintage, xây dựng bằng Flutter.
> 96 files Dart · ~8,900 LOC · 10 test files · 2 Cloud Function files (ready for Blaze)

---

## Thay đổi so với R4

| Hạng mục | R4 | R5 |
|---|---|---|
| FCM dedup | In-memory only (same device) | Firestore-based lock (cross-device) + in-memory fast path + TTL cleanup 3 days |
| Currency mixed | Hiển thị "Nhiều loại tiền" | Approximate balance "≈ 1.250.000đ" via static exchange rates |
| Activity feed | Hiển thị từng activity riêng | Group by user+day ("đã thêm 3 giao dịch"), priority styling join/leave |
| Empty states | Generic "Không có..." | Smart hints: "thử nhập 'ăn trưa 50k' 👇", "Đặt ngân sách →", "Thêm giao dịch để xem biểu đồ" |
| Export | Không có | CSV export: all transactions → temp file → share sheet |
| Privacy | Không có | Privacy section + bottom sheet giải thích bảo mật |
| Stream optimization | CategoryListScreen dùng stream | Chuyển sang one-shot get + manual reload |
| Security rules | 7 subcollections | +notification_events subcollection |
| Dependencies | 9 | 11 (+share_plus, path_provider) |
| Files | 95 | 96 (+export_service.dart) |
| L10n keys | ~190 | ~200 |

---

## Kiến trúc tổng quan

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Data**: Firestore-first — `FirestoreRepository<T>` base (CRUD + streams + atomic + ReadCounter)
- **Offline**: Firestore persistence enabled, unlimited cache
- **Auth**: Firebase Auth — anonymous auto → upgrade to email
- **Balance**: Atomic via `firestore.runTransaction()` — 8 edge cases tested
- **Notifications**: Client-side FCM push — server key from Firestore, cross-device dedup via Firestore lock, retry 2x, stale cleanup, debounce 2s
- **Error handling**: AppException + ErrorMapper → l10n messages + retry
- **Caching**: Category in-memory cache, Quick Add keywords persisted + LRU 100
- **Currency**: 8 currencies + static exchange rates + approximate balance
- **DI**: ServiceLocator singleton (`sl`) — 9 services
- **L10n**: Vietnamese / English, ~200 keys

---

## Tính năng chi tiết

### 1. Auth
- Anonymous auto sign-in → dùng ngay
- Email login/register, upgrade anonymous via linkWithEmail
- User-friendly error messages (ErrorMapper)
- Smart login prompt (≥5 txns OR ≥3 days)

### 2. Account System
- Personal + Family unified schema
- Auto-create personal account + "Ví chính"
- Persist lastAccountId + lastWalletId, skip AccountPicker nếu đã có

### 3. Family V2
- Tạo gia đình + seed categories + "Ví chung"
- Invite bằng link (7 ngày expiry) + join by link dialog
- Family promo "Chia sẻ chi tiêu với người thân 👨👩👧"
- Member avatars (initials), owner/member roles
- Activity feed V2: rich messages, user names, relative time, group by user+day, priority styling join/leave
- Activity log: transactions + wallet create/delete + join/leave
- FCM notification cho invite + transaction (family only)

### 4. Wallet
- CRUD + multi-currency (8 currencies)
- Auto-create "Ví chính" cho anonymous
- Realtime StreamBuilder, atomic balance
- Recalculate balance tool
- Activity log tạo/xóa ví

### 5. Transaction
- Atomic CRUD via `runTransaction` (8 edge cases tested)
- Auto-select last used wallet
- Budget alert trong form
- Lazy loading per month (direct query)
- FCM notification + activity log
- Undo snackbar trong Quick Add

### 6. Quick Add
- Bottom bar, parse 1 dòng ("ăn sáng 50k")
- 30+ keywords vi/en, learned (persisted Firestore + LRU 100 + debounce 5s)
- Fuzzy match → fallback to full form
- Undo snackbar 4s
- Clear learned trong Settings

### 7. Budget & Insight
- Budget per category (monthly), upsert, optimized queries
- Progress bar (xanh/vàng/đỏ), budget summary card trên Home
- Budget alert trong TransactionFormScreen
- Monthly insight: summary + highlight ("Tiết kiệm được X 🎉") + top spending + vs last month bars
- Premium gate placeholder

### 8. Notifications (FCM)
- Token registration + refresh + duplicate prevention
- Client-side push (legacy HTTP API), server key from Firestore `config/fcm`
- Cross-device dedup: Firestore lock `notification_events/{eventId}` + in-memory fast path
- Retry 2x (500ms → 1s), timeout 10s, stale token cleanup
- Rich messages: invite "Bạn được mời vào gia đình {name}", transaction "chi {amount} {category}"
- Anti-spam debounce 2s (batch rapid transactions)
- TTL cleanup notification_events > 3 days (1x/day)
- Tap navigation: invite → JoinFamilyScreen, transaction → HomeScreen
- Cloud Functions ready (`functions/index.js`)

### 9. Charts
- 4 views: Trend / Daily / Breakdown / Summary
- Smart empty state: "Thêm giao dịch để xem biểu đồ"

### 10. Home Screen
- Balance card: approximate total for mixed currencies ("≈ 1.250.000đ" + tooltip)
- Wallet row + currency per wallet
- Chart section
- Budget summary (smart empty: "Đặt ngân sách →")
- Savings highlight ("🎉 Tiết kiệm được 500k")
- Streak counter ("🔥 5 ngày liên tiếp")
- Login prompt (smart trigger)
- Transaction section (smart empty: "thử nhập 'ăn trưa 50k' 👇")
- QuickAddBar (hoặc first-run hint)
- Network offline banner

### 11. Settings
- Account info / register prompt
- Default currency picker (8)
- Language Vi/En
- Export CSV → share sheet
- Privacy section + detail bottom sheet
- Clear learned keywords
- Firestore reads debug (per-screen breakdown)

### 12. Export CSV
- Query all transactions, resolve wallet/category names
- CSV format: date, type, amount, category, wallet, note
- UTF-8 BOM, comma escaping
- Temp file → share_plus share sheet

### 13. Multi-Currency
- 8 currencies: VND, USD, EUR, GBP, JPY, KRW, CNY, THB
- Static exchange rates (VND base)
- `Currency.convert()` + `Currency.toVnd()`
- Approximate balance for mixed currencies
- Format: full + compact, symbol position, decimals

### 14. Success Feedback
- Monthly highlight: "Tiết kiệm được X 🎉" / "Chi nhiều hơn X"
- Home savings card (khi net > 0)
- Streak counter (daily usage tracking)

### 15. Trust & Privacy
- Privacy section trong Settings
- Bottom sheet: mã hóa, không bán dữ liệu, Firestore Security Rules
- Export CSV cho data portability

---

## Firestore Schema

```
accounts/{accountId}/
  ├── wallets/{docId}              → name, balance, currency, created_at, updated_at
  ├── transactions/{docId}         → wallet_id, category_id, type, amount, note, date, created_by, items[], created_at, updated_at
  ├── categories/{docId}           → name, type, icon, created_at, updated_at
  ├── budgets/{docId}              → category_id, amount_limit, period, created_at, updated_at
  ├── activities/{docId}           → user_id, action, description, created_at
  └── notification_events/{eventId} → created_at (cross-device dedup lock)

users/{userId}/
  ├── email, display_name, account_ids[], created_at
  ├── settings/prefs → locale, default_currency, last_account_id, last_wallet_id, quick_add_keywords, streak_last_date, streak_count
  └── fcm_tokens/{token} → token, updated_at

invites/{tokenId}/ → account_id, created_by, created_at, expires_at
config/fcm         → server_key (read-only)
```

### Security Rules (10 match blocks)

| Path | Read | Write | Validation |
|---|---|---|---|
| `users/{userId}/**` | isCurrentUser | isCurrentUser | — |
| `accounts/{accountId}` | isMember | create: uid in member_ids. update/delete: isOwner | — |
| `.../wallets` | isMember | isMember | name.size() > 0 |
| `.../transactions` | isMember | isMember | amount > 0, type in [income, expense] |
| `.../categories` | isMember | isMember | name.size() > 0 |
| `.../budgets` | isMember | isMember | amount_limit > 0 |
| `.../activities` | isMember | create: isMember + user_id == uid. update/delete: deny | — |
| `.../notification_events` | isMember | create/delete: isMember. update: deny | — |
| `invites/{tokenId}` | authenticated | create: isMember of account. update/delete: deny | — |
| `config/{docId}` | authenticated | deny | — |

### Composite Indexes (5)

| Collection | Fields | Query |
|---|---|---|
| transactions | wallet_id + date DESC | Recent by wallet |
| transactions | wallet_id + date ASC | Date range by wallet |
| categories | type + name ASC | Categories by type |
| transactions | category_id + type + date ASC | checkBudget |
| transactions | type + date ASC | getBudgetStatuses |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | Cloud Firestore (offline persistence) |
| Auth | Firebase Auth (anonymous + email + link) |
| Notifications | Firebase Messaging + http (client-side FCM) |
| Charts | fl_chart |
| Export | share_plus + path_provider |
| Fonts | SpecialElite, PatrickHand (bundled) |
| Swipe | flutter_slidable |
| L10n | flutter_localizations + custom S helper |

---

## Project Structure

```
lib/                              # 96 files, ~8,900 LOC
├── core/
│   ├── constants/                # category_icons, currency (8 + exchange rates + convert)
│   ├── debug/                    # ReadCounter (per-screen + streams)
│   ├── enums/                    # transaction_type
│   ├── firestore/                # FirestoreRepository<T>
│   ├── l10n/                     # vi (~200 keys), en (~200 keys), S helper
│   ├── theme/                    # AppColors, AppTextStyles, AppSpacing, AppTheme
│   ├── app_exception.dart
│   ├── app_state.dart
│   ├── error_mapper.dart
│   ├── premium_gate.dart
│   └── service_locator.dart      # 9 services
├── common/widgets/               # 19 widgets
├── features/
│   ├── account/                  # Account, InviteToken, AccountService, 4 screens
│   ├── auth/                     # AuthService, 2 screens
│   ├── budget/                   # Budget, BudgetStatus, optimized queries, 3 screens, 2 widgets
│   ├── category/                 # Category, in-memory cache, 2 screens
│   ├── export/                   # ExportService (CSV)
│   ├── home/                     # HomeScreen (approx balance, savings, streak, smart empties)
│   ├── notification/             # NotificationService (cross-device dedup, retry, debounce)
│   ├── quick_add/                # QuickAddParser (persist, LRU, fuzzy), QuickAddBar (undo)
│   ├── settings/                 # SettingService (+streak), SettingScreen (export, privacy, debug)
│   ├── transaction/              # Atomic CRUD, lazy loading, 2 screens, charts/, widgets/
│   └── wallet/                   # Wallet (+activity log), recalculate, 3 screens
├── utils/                        # AmountFormatter, DateFormatter (+relative), NavigatorX
└── main.dart

test/                             # 10 test files
functions/                        # Cloud Functions (ready for Blaze)
```

---

## Known Issues

1. **Client-side FCM push** — Server key in Firestore `config/fcm`. Migrate to Cloud Functions on Blaze plan.

2. **fcm_tokens read access** — Security rules restrict to isCurrentUser → client-side push may fail reading other users' tokens. Needs rule expansion or Cloud Functions.

3. **Test coverage** — 10 test files cover utils, models, parser, balance logic, error mapper. No widget/integration tests.

4. **Static exchange rates** — Hardcoded, need manual update. No live API.

5. **Deploy pending** — `firebase deploy --only firestore:indexes,firestore:rules` cần chạy thủ công.

---

## Evolution Summary

| Round | Focus | Files | LOC | L10n | Tests |
|---|---|---|---|---|---|
| R1 | SQLite + manual sync | 78 | ~7,600 | ~120 | 6 |
| R2 | Firestore-first + features (Quick Add, Budget, Currency, Family V2, Onboarding) | 91 | ~7,650 | ~160 | 7 |
| R3 | Production hardening (atomic, security, indexes, errors, notifications, queries) | 95 | ~8,200 | ~180 | 8 |
| R4 | Polish (FCM reliability, notification UX, activity V2, Quick Add undo, read optimization, onboarding, success feedback) | 95 | ~8,600 | ~190 | 10 |
| R5 | Trust & UX (cross-device dedup, currency approximation, activity grouping, smart empties, CSV export, privacy, stream optimization) | 96 | ~8,900 | ~200 | 10 |
