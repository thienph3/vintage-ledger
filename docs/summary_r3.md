# Vintage Ledger — Summary R3

> Ứng dụng quản lý thu chi cá nhân & gia đình, phong cách vintage, xây dựng bằng Flutter.
> 95 files Dart · ~8,200 LOC · 7 test files · 2 Cloud Function files (ready for Blaze)

---

## Thay đổi so với R2

| Hạng mục | R2 | R3 |
|---|---|---|
| Balance update | Sequential (add txn → updateBalance riêng) | Atomic (`firestore.runTransaction`) |
| Security rules | Cũ từ sync era, thiếu budgets/activities/invites/config | Hoàn chỉnh: isMember, isOwner, data validation, per-collection rules |
| Firestore indexes | Cũ (updated_at, deleted_at) | 3 composite indexes đúng cho queries hiện tại |
| Error handling | Raw Firebase exception | AppException + ErrorMapper → l10n user-friendly messages + retry |
| Quick Add learning | In-memory only | Persist Firestore + debounce 5s + LRU 100 + flush on app pause |
| Budget queries | Gọi getDashboard() (load toàn bộ) | Query trực tiếp expense transactions per category |
| Transaction list | Gọi getDashboard() per month | Query getByDateRange() trực tiếp |
| Notifications | Không có | FCM push via client-side legacy API (Spark plan compatible) |
| Debug | Không có | ReadCounter hook vào FirestoreRepository + hiển thị trong Settings |
| Services | 8 | 9 (+NotificationService) |
| Dependencies | 7 | 9 (+firebase_messaging, http) |
| Files | 91 | 95 |

---

## Kiến trúc tổng quan

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Data**: Firestore-first — `FirestoreRepository<T>` base class với CRUD + realtime streams + public `collection`/`firestore` getters cho atomic transactions
- **Offline**: Firestore persistence enabled, unlimited cache
- **Auth**: Firebase Auth — anonymous auto → upgrade to email via linkWithEmail
- **Balance**: Atomic via `firestore.runTransaction()` — create/update/delete transaction + wallet balance trong 1 operation
- **Notifications**: Client-side FCM push (legacy HTTP API) — server key stored in Firestore `config/fcm`, fetched on init
- **Error handling**: AppException + ErrorMapper (Firestore + Auth errors → l10n keys) + showErrorSnackBar with retry
- **DI**: ServiceLocator singleton (`sl`) — 9 services
- **State**: AppState (currentUserId, currentAccountId, hasAccount)
- **L10n**: Vietnamese (mặc định) / English, ~180 keys
- **Theme**: Vintage — 2 fonts (SpecialElite, PatrickHand), paper background, ink colors

---

## Tính năng chi tiết

### 1. Xác thực (Auth)

| Tính năng | Mô tả |
|---|---|
| Anonymous auto sign-in | Mở app → tự đăng nhập anonymous → dùng ngay |
| Đăng nhập email | Email + password, error messages user-friendly (wrongPassword, userNotFound...) |
| Đăng ký / Upgrade | Tạo mới hoặc link anonymous → email. Auth errors mapped qua ErrorMapper |
| Đăng xuất | Remove FCM token → sign out → LoginScreen |
| Delayed login prompt | LoginPromptCard trên Home khi anonymous + ≥3 transactions |

### 2. Hệ thống Account

| Tính năng | Mô tả |
|---|---|
| Personal account | Tạo tự động khi sign-in |
| Family account | Tạo thủ công + seed categories + "Ví chung" mặc định |
| Unified schema | `accounts/{accountId}/` cho cả personal và family |
| Chọn account | AccountPickerScreen — skip nếu đã có lastAccountId |
| Persist context | lastAccountId + lastWalletId lưu Firestore, restore on startup |

### 3. Quản lý gia đình (Family V2)

| Tính năng | Mô tả |
|---|---|
| Tạo gia đình | Nhập tên → seed categories + "Ví chung" |
| Invite bằng link | Token 7 ngày expiry → copy link → share. FCM notification gửi đến members |
| Join by link | JoinFamilyScreen: validate token → join |
| Member management | Owner remove member, member tự rời, owner rời → chuyển quyền |
| Member avatars | CircleAvatar initials, owner màu inkBlue |
| Activity feed | Realtime stream activities/ + FCM notification cho family transactions |
| Created by | Icon people_outline cho transactions tạo bởi member khác |

### 4. Quản lý ví (Wallet)

| Tính năng | Mô tả |
|---|---|
| CRUD | Tạo (tên + số dư + currency), sửa, xóa (swipe) |
| Auto-create | "Ví chính" cho anonymous user lần đầu |
| Multi-currency | 8 currencies (VND, USD, EUR, GBP, JPY, KRW, CNY, THB) |
| Realtime | StreamBuilder cho danh sách + chi tiết |
| Balance atomic | Update qua `runTransaction` khi tạo/sửa/xóa transaction |
| Recalculate | `recalculateBalance()` tool cho fix data inconsistent |

### 5. Quản lý giao dịch (Transaction)

| Tính năng | Mô tả |
|---|---|
| Atomic create | `runTransaction`: add doc + update wallet balance |
| Atomic update | `runTransaction`: revert old + apply new. Hỗ trợ wallet change |
| Atomic delete | `runTransaction`: revert balance + delete doc |
| Auto-select wallet | Last used wallet từ Firestore settings |
| Items embedded | Transaction items trong Firestore doc |
| Budget alert | Warning khi category gần/vượt budget |
| Lazy loading | TransactionListScreen query getByDateRange() trực tiếp per month |
| Nhóm | Group by ngày / tuần / tháng |
| Notification | FCM push đến family members khi tạo transaction |

### 6. Quick Add

| Tính năng | Mô tả |
|---|---|
| QuickAddBar | Bottom bar trên Home — gõ 1 dòng, parse tự động |
| Amount parsing | "50k", "10tr", "1.5tr", "2 tỷ" |
| Category matching | 30+ keywords vi/en, learned keywords ưu tiên |
| Keyword learning | Persist Firestore, debounce 5s, LRU 100, flush on app pause |
| Clear learned | Option trong Settings hiển thị count + tap to clear |
| Realtime preview | Amount + category chip + type color |
| Fallback | Thiếu category → mở full form với data pre-filled |

### 7. Ngân sách & Insight (Budget)

| Tính năng | Mô tả |
|---|---|
| Budget per category | Hạn mức monthly cho expense categories, upsert |
| Optimized tracking | Query expense transactions trực tiếp, không qua getDashboard |
| Progress UI | Xanh < 80%, vàng 80-100%, đỏ > 100% |
| Budget summary | Card trên Home hiển thị budgets gần/vượt limit |
| Budget alert | Warning trong TransactionFormScreen |
| Monthly insight | Tổng thu/chi/net, top 3 spending, vs tháng trước |
| Spending trend | Bar chart per category: tháng này vs tháng trước |
| Premium gate | PremiumGate.isUnlocked placeholder |

### 8. Notifications (FCM)

| Tính năng | Mô tả |
|---|---|
| FCM token registration | Lưu vào `users/{userId}/fcm_tokens/{token}`, auto refresh |
| Client-side push | Legacy HTTP API, server key từ Firestore `config/fcm` (không hardcode trong APK) |
| Invite notification | Gửi đến family members khi tạo invite link |
| Transaction notification | Gửi đến family members khi tạo transaction (chỉ family accounts) |
| Tap navigation | invite → JoinFamilyScreen, transaction → HomeScreen |
| Permission | Request on init |
| Cloud Functions ready | `functions/index.js` sẵn sàng deploy khi chuyển Blaze plan |

### 9. Biểu đồ (Charts)

| Tính năng | Mô tả |
|---|---|
| Trend / Daily / Breakdown / Summary | 4 chart views với animated switch |

### 10. Màn hình chính (Home)

| Tính năng | Mô tả |
|---|---|
| Balance card | Tổng số dư, ẩn/hiện, mixed currencies detection |
| Wallet row | Horizontal scroll + currency per wallet |
| Chart section | Biểu đồ tháng |
| Budget summary | Cảnh báo budgets gần/vượt limit + link insight |
| Login prompt | Cho anonymous users |
| QuickAddBar | Bottom bar (hoặc first-run hint khi chưa có wallet) |
| Network banner | Offline indicator |
| Account switcher | Icon ↔ cho email users |

### 11. Cài đặt (Settings)

| Tính năng | Mô tả |
|---|---|
| Account info | Email/name hoặc register prompt |
| Đăng xuất | Remove FCM token + sign out |
| Default currency | 8 currencies picker |
| Ngôn ngữ | Vi / En runtime switch |
| Clear learned keywords | Hiển thị count + tap to clear |
| Firestore reads (debug) | ReadCounter hiển thị reads this session + reset |

### 12. Error Handling

| Tính năng | Mô tả |
|---|---|
| AppException | Custom exception với code + l10n message key |
| ErrorMapper | Firestore errors (unavailable, permission-denied, resource-exhausted...) + Auth errors (wrong-password, user-not-found, email-already-in-use, weak-password...) → l10n keys |
| showErrorSnackBar | Mapped message + optional retry callback |
| Auth screens | Login/Register hiển thị user-friendly error messages |
| Form screens | try/catch + showErrorSnackBar cho tất cả save/delete |

### 13. Multi-Currency

| Tính năng | Mô tả |
|---|---|
| 8 currencies | VND, USD, EUR, GBP, JPY, KRW, CNY, THB với symbol, decimals, symbolBefore |
| Format | VND → "50.000đ", USD → "$50.00", compact: "50k", "10tr", "$1.5m" |
| Mixed currencies | Home hiển thị "Nhiều loại tiền" |

### 14. UI/UX

| Widget | Mô tả |
|---|---|
| AppScaffold + LedgerHeader | Vintage AppBar + divider |
| LedgerCard | Border, shadow, radius 12 |
| AmountText | Màu + currency + compact |
| SwipeListItem | Swipe-to-delete + confirm |
| AsyncContent | Loading/error/content |
| ErrorSnackBar | Red + l10n message + retry |
| NetworkStatusBanner | Offline indicator |
| LoginPromptCard | Delayed login prompt |
| BudgetProgressTile | Color-coded progress bar |
| BudgetSummaryCard | Home budget alerts |
| QuickAddBar | Bottom input + preview |

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
  ├── settings/prefs        → locale, default_currency, last_account_id, last_wallet_id, quick_add_keywords
  └── fcm_tokens/{token}    → token, updated_at

invites/{tokenId}/
  → account_id, created_by, created_at, expires_at

config/fcm
  → server_key (read-only, set via Firebase Console)
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

### Composite Indexes

| Collection | Fields | Query |
|---|---|---|
| transactions | wallet_id ASC + date DESC | Recent by wallet |
| transactions | wallet_id ASC + date ASC | Date range by wallet |
| categories | type ASC + name ASC | Categories by type |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | Cloud Firestore (offline persistence, unlimited cache) |
| Auth | Firebase Auth (anonymous + email/password + link) |
| Notifications | Firebase Messaging (client-side FCM legacy API) |
| HTTP | http package (FCM push) |
| Charts | fl_chart |
| Fonts | SpecialElite, PatrickHand (bundled) |
| Swipe actions | flutter_slidable |
| L10n | flutter_localizations + custom S helper |

---

## Project Structure

```
lib/                          # 95 Dart files, ~8,200 LOC
├── core/
│   ├── constants/            # category_icons, currency (8 currencies)
│   ├── debug/                # ReadCounter
│   ├── enums/                # transaction_type
│   ├── firestore/            # FirestoreRepository<T> base (CRUD + streams + atomic helpers)
│   ├── l10n/                 # vi (~180 keys), en (~180 keys), S helper
│   ├── theme/                # AppColors, AppTextStyles, AppSpacing, AppTheme
│   ├── app_exception.dart    # AppException(code, message)
│   ├── app_state.dart        # currentUserId, currentAccountId
│   ├── error_mapper.dart     # Firestore + Auth error → AppException
│   ├── premium_gate.dart     # Placeholder for monetization
│   └── service_locator.dart  # 9 services
├── common/widgets/           # 19 reusable widgets
├── features/
│   ├── account/              # Account, InviteToken, AccountService, 4 screens
│   ├── auth/                 # AuthService (anonymous + email + link + error mapping), 2 screens
│   ├── budget/               # Budget, BudgetStatus, BudgetRepo/Service, 3 screens, 2 widgets
│   ├── category/             # Category, CategoryRepo/Service, 2 screens
│   ├── home/                 # HomeScreen (streams + dashboard + quick add + budget + login prompt)
│   ├── notification/         # NotificationService (FCM client-side push + Firestore key)
│   ├── quick_add/            # QuickAddParser (persist + LRU), QuickAddBar
│   ├── settings/             # SettingService (Firestore), SettingScreen (currency + language + debug)
│   ├── transaction/          # Transaction models, TransactionRepo/Service (atomic), 2 screens, charts/, widgets/
│   └── wallet/               # Wallet, WalletRepo/Service (recalculate), 3 screens
├── utils/                    # AmountFormatter (multi-currency), DateFormatter, NavigatorX
└── main.dart                 # Firebase init, anonymous auth, lifecycle observer, routing

functions/                    # Cloud Functions (ready for Blaze plan)
├── index.js                  # onInviteCreated, onTransactionCreated
└── package.json
```

---

## Known Issues

1. **Client-side FCM push (security)** — Server key stored in Firestore `config/fcm`. Authenticated users can read it. Mitigation: chuyển sang Cloud Functions khi lên Blaze plan. `functions/index.js` đã sẵn sàng.

2. **fcm_tokens read access** — NotificationService đọc `users/{otherUserId}/fcm_tokens/` để collect tokens. Security rules hiện chỉ cho isCurrentUser đọc → client-side push sẽ bị deny cho tokens của user khác. Cần mở rộng rules hoặc chuyển sang Cloud Functions.

3. **Test coverage thấp** — 7 test files chỉ cover utils, models, enum, parser. Không có test cho services, repositories, atomic transactions, hoặc widget tests.

4. **setState sau dispose** — Một số screen gọi async rồi setState mà chỉ check mounted ở một số chỗ.

5. **Currency conversion chưa có** — Mixed currencies không thể tính tổng balance. Cần exchange rate API.

6. **Budget composite index thiếu** — `checkBudget` query `where('category_id') + where('type') + where('date', >=)` cần composite index chưa có trong `firestore.indexes.json`.

7. **Firestore reads trên streams** — ReadCounter chỉ count one-shot reads (getById, getAll). Stream reads (watchAll, watchById) không được count.

8. **Anonymous user upgrade edge case** — Khi anonymous upgrade to email, nếu email đã có account khác → `linkWithEmail` fail. Cần handle credential-already-in-use error gracefully.
