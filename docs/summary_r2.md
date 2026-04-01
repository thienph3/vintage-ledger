# Vintage Ledger — Summary R2

> Ứng dụng quản lý thu chi cá nhân & gia đình, phong cách vintage, xây dựng bằng Flutter.
> 91 files Dart · ~7,650 LOC · 7 test files

---

## Thay đổi so với R1

| Hạng mục | R1 (v0.0.1) | R2 |
|---|---|---|
| Data layer | SQLite local-first + manual sync | Firestore-first + offline cache |
| Auth | Email/password + skip login (local) | Anonymous auto → upgrade to email |
| Sync | Manual push/pull + tombstone + dirty flags | Không cần — Firestore realtime + offline persistence |
| Models | int ID + sync fields (is_synced, remote_id, account_id) | String ID (Firestore doc ID), clean models |
| List screens | setState + CrudListMixin | StreamBuilder (realtime) |
| Tính năng mới | — | Quick Add, Budget & Insight, Multi-Currency, Family V2 (invite link + activity), Onboarding UX |
| Dependencies | sqflite, sqflite_common_ffi, path, connectivity_plus | Đã xóa — chỉ còn Firebase stack |
| Files | 78 files | 91 files |

---

## Kiến trúc tổng quan

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Data**: Firestore-first — `FirestoreRepository<T>` base class với CRUD + realtime streams
- **Offline**: Firestore persistence enabled, unlimited cache — đọc/ghi khi offline, auto sync khi online
- **Auth**: Firebase Auth — anonymous auto sign-in → upgrade to email via `linkWithEmail`
- **DI**: ServiceLocator singleton (`sl`) — 8 services
- **State**: AppState (currentUserId, currentAccountId, hasAccount)
- **L10n**: Vietnamese (mặc định) / English, ~160 keys
- **Theme**: Vintage — 2 fonts (SpecialElite, PatrickHand), paper background, ink colors

---

## Tính năng chi tiết

### 1. Xác thực (Auth)

| Tính năng | Mô tả |
|---|---|
| Anonymous auto sign-in | Mở app → tự đăng nhập anonymous → dùng ngay, không friction |
| Đăng nhập email | Email + password qua Firebase Auth |
| Đăng ký | Tạo account mới hoặc upgrade anonymous → email (linkWithEmail) |
| Đăng xuất | Xóa session, quay về LoginScreen |
| Delayed login prompt | `LoginPromptCard` hiển thị trên Home khi anonymous + ≥3 transactions |

### 2. Hệ thống Account

| Tính năng | Mô tả |
|---|---|
| Personal account | Tạo tự động khi sign-in (anonymous hoặc email) |
| Family account | Tạo thủ công, chia sẻ data giữa nhiều thành viên |
| Unified schema | Personal và family dùng chung `accounts/{accountId}/` trên Firestore |
| Chọn account | AccountPickerScreen — skip nếu đã có lastAccountId |
| Persist context | Lưu lastAccountId + lastWalletId vào Firestore settings, restore on startup |

### 3. Quản lý gia đình (Family V2)

| Tính năng | Mô tả |
|---|---|
| Tạo gia đình | Nhập tên → seed categories + tạo "Ví chung" mặc định |
| Invite bằng link | Tạo invite token (7 ngày expiry) → copy link → share |
| Join by link | JoinFamilyScreen: validate token → join family |
| Xóa thành viên | Owner remove member |
| Rời gia đình | Member tự rời, owner rời → chuyển quyền hoặc xóa |
| Xóa gia đình | Owner xóa toàn bộ (subcollections + activities + account doc) |
| Member avatars | CircleAvatar với initials, owner có màu inkBlue |
| Activity feed | Realtime stream `activities/` — log ai tạo transaction gì |
| Created by | Icon people_outline bên cạnh transactions tạo bởi member khác |

### 4. Quản lý ví (Wallet)

| Tính năng | Mô tả |
|---|---|
| Tạo ví | Nhập tên + số dư + chọn currency |
| Auto-create | Wallet "Ví chính" tạo tự động cho anonymous user lần đầu |
| Sửa ví | Đổi tên, số dư, currency |
| Xóa ví | Swipe-to-delete với confirm dialog |
| Danh sách ví | StreamBuilder realtime |
| Chi tiết ví | Realtime balance + biểu đồ + giao dịch gần đây |
| Multi-currency | Mỗi wallet có currency riêng (VND, USD, EUR, GBP, JPY, KRW, CNY, THB) |

### 5. Quản lý giao dịch (Transaction)

| Tính năng | Mô tả |
|---|---|
| Tạo giao dịch | Chọn loại, ví (auto-select last used), danh mục, số tiền, ngày giờ, ghi chú |
| Sửa giao dịch | Revert balance cũ → apply balance mới |
| Xóa giao dịch | Revert balance |
| Mục chi tiết | Transaction items embedded trong Firestore doc |
| Validation | Amount > 0, tổng items ≤ amount, wallet required |
| Nhóm giao dịch | Group by ngày / tuần / tháng |
| Budget alert | Warning trong form khi category gần/vượt budget |
| Error handling | try/catch + showErrorSnackBar cho tất cả write operations |

### 6. Quick Add

| Tính năng | Mô tả |
|---|---|
| QuickAddBar | Bottom bar trên HomeScreen — gõ 1 dòng, parse tự động |
| Amount parsing | "50k" → 50,000 · "10tr" → 10,000,000 · "1.5tr" → 1,500,000 · "2 tỷ" → 2B |
| Category matching | 30+ keywords vi/en → category: "ăn/cơm/phở" → Ăn uống, "cf/coffee" → Cà phê |
| Realtime preview | Hiển thị amount + category chip + type color khi gõ |
| Keyword learning | Lưu mapping user đã dùng, ưu tiên hơn built-in map |
| Fallback | Thiếu category → mở TransactionFormScreen với data pre-filled |

### 7. Quản lý danh mục (Category)

| Tính năng | Mô tả |
|---|---|
| CRUD | Tạo/sửa/xóa danh mục với tên, loại (thu/chi), icon |
| Seed mặc định | 9 categories khi tạo account |
| StreamBuilder | Danh sách realtime |
| Lọc theo loại | CategoryDropdown lọc theo income/expense |
| Tạo nhanh | Nút "+" trong dropdown |

### 8. Ngân sách & Insight (Budget)

| Tính năng | Mô tả |
|---|---|
| Budget per category | Đặt hạn mức chi tiêu monthly cho từng expense category |
| Upsert | Nếu đã có budget cho category → update thay vì tạo mới |
| Budget tracking | Tính % used = tổng chi tháng / limit |
| Progress UI | Progress bar: xanh < 80%, vàng 80-100%, đỏ > 100% |
| Budget summary | Card trên Home hiển thị budgets gần/vượt limit |
| Budget alert | Warning trong TransactionFormScreen khi chọn category gần/vượt budget |
| Monthly insight | Tổng thu/chi/net, top 3 spending, so sánh vs tháng trước |
| Spending trend | Bar chart so sánh chi tiêu per category: tháng này vs tháng trước |
| Premium gate | `PremiumGate.isUnlocked` placeholder cho monetization |

### 9. Biểu đồ (Charts)

| Tính năng | Mô tả |
|---|---|
| Trend chart | Line chart thu/chi theo ngày (fl_chart) |
| Daily chart | Bar chart so sánh thu/chi từng ngày |
| Breakdown chart | Pie chart tỷ lệ chi theo danh mục |
| Summary view | Tổng thu, tổng chi, chênh lệch, số giao dịch, ngày chi nhiều nhất |
| Animated switch | Chuyển đổi giữa các view với animation |

### 10. Màn hình chính (Home)

| Tính năng | Mô tả |
|---|---|
| Balance card | Tổng số dư, tap ẩn/hiện, detect mixed currencies |
| Thu chi tháng | Tổng thu và tổng chi tháng hiện tại |
| Wallet row | Horizontal scroll + hiển thị currency per wallet |
| Chart section | Biểu đồ tháng hiện tại |
| Budget summary | Card cảnh báo budgets gần/vượt limit |
| Login prompt | Card "Đăng ký để đồng bộ" cho anonymous users |
| Recent transactions | 5 giao dịch gần đây |
| QuickAddBar | Bottom bar thêm giao dịch nhanh |
| First-run hint | Hint text khi chưa có wallet |
| Network banner | Offline indicator khi mất mạng |
| Pull-to-refresh | Kéo xuống reload dashboard |
| Account switcher | Icon ↔ (chỉ khi đã login email) |

### 11. Cài đặt (Settings)

| Tính năng | Mô tả |
|---|---|
| Thông tin tài khoản | Email, display name (hoặc prompt đăng ký cho anonymous) |
| Đăng xuất | Xóa session Firebase Auth |
| Default currency | Chọn currency mặc định cho wallets mới |
| Chuyển ngôn ngữ | Vietnamese / English, lưu vào Firestore settings |

### 12. Đa ngôn ngữ (L10n)

| Tính năng | Mô tả |
|---|---|
| Vietnamese (mặc định) | ~160 keys |
| English | ~160 keys |
| Locale toggle | Widget chuyển ngôn ngữ trên LoginScreen |
| Runtime switch | Đổi ngôn ngữ trong Settings, apply ngay |

### 13. Multi-Currency

| Tính năng | Mô tả |
|---|---|
| 8 currencies | VND, USD, EUR, GBP, JPY, KRW, CNY, THB |
| Currency per wallet | Mỗi wallet có currency riêng |
| Format theo currency | VND → "50.000đ", USD → "$50.00", EUR → "€50,00" |
| Compact format | VND → "50k", "10tr", "2 tỷ" · USD → "$50k", "$1.5m" |
| Mixed currencies | Home balance hiển thị "Nhiều loại tiền" khi wallets khác currency |
| Default currency setting | Chọn trong Settings |

### 14. UI/UX

| Tính năng | Mô tả |
|---|---|
| Vintage theme | Paper background, ink colors, SpecialElite + PatrickHand fonts |
| AppScaffold | Scaffold wrapper với LedgerHeader |
| LedgerCard | Card container với border, shadow, border-radius 12 |
| AmountText | Số tiền có màu + currency support + compact format |
| SwipeListItem | Swipe-to-delete với confirm dialog |
| AsyncContent | Loading/error/content wrapper |
| EmptyState | Placeholder text cho danh sách trống |
| FormSaveButton | Nút Lưu/Cập nhật thống nhất |
| DeleteConfirmation | Dialog xác nhận xóa dùng chung |
| ErrorSnackBar | Red snackbar với nút dismiss cho write errors |
| NetworkStatusBanner | Offline indicator dùng Firestore snapshot metadata |
| LoginPromptCard | Delayed login prompt cho anonymous users |
| AmountInputField | Input số tiền với keypad + currency format |
| TypeSelector | Toggle income/expense |

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
  └── settings/prefs        → locale, default_currency, last_account_id, last_wallet_id

invites/{tokenId}/
  → account_id, created_by, created_at, expires_at
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | Cloud Firestore (offline persistence enabled) |
| Auth | Firebase Auth (anonymous + email/password + link) |
| Charts | fl_chart |
| Fonts | SpecialElite, PatrickHand (bundled) |
| Swipe actions | flutter_slidable |
| L10n | flutter_localizations + custom S helper |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # category_icons, currency
│   ├── enums/           # transaction_type
│   ├── firestore/       # FirestoreRepository<T> base class
│   ├── l10n/            # vi, en, S helper
│   ├── theme/           # AppColors, AppTextStyles, AppSpacing, AppTheme
│   ├── app_state.dart
│   ├── premium_gate.dart
│   └── service_locator.dart
├── common/
│   └── widgets/         # 19 reusable widgets
├── features/
│   ├── account/         # Account, InviteToken, AccountService, AccountPicker, FamilyDetail, FamilyForm, JoinFamily
│   ├── auth/            # AuthService (anonymous + email + link), LoginScreen, RegisterScreen
│   ├── budget/          # Budget, BudgetStatus, BudgetRepo, BudgetService, BudgetList, BudgetForm, MonthlyInsight, BudgetProgressTile, BudgetSummaryCard
│   ├── category/        # Category, CategoryRepo, CategoryService, CategoryList, CategoryForm
│   ├── home/            # HomeScreen (dashboard + streams + quick add)
│   ├── quick_add/       # QuickAddParser, QuickAddBar
│   ├── settings/        # SettingService (Firestore), SettingScreen
│   ├── transaction/     # Transaction, TransactionItem, DashboardData, TransactionRepo, TransactionService, TransactionForm, TransactionList, charts/, widgets/
│   └── wallet/          # Wallet, WalletRepo, WalletService, WalletList, WalletForm, WalletDetail
├── utils/               # AmountFormatter, DateFormatter, NavigatorX
└── main.dart            # Firebase init, anonymous auth, routing
```

---

## Known Issues

1. **Balance không atomic trên Firestore** — `createTransaction` gọi `add` rồi `updateBalance` riêng biệt. Nếu app crash giữa 2 operations, balance sẽ sai. Cần Firestore transaction hoặc Cloud Function.

2. **TransactionListScreen lazy loading** — Hiện dùng `getDashboard()` thay vì query trực tiếp theo date range. Cần refactor để load tháng cũ hơn khi scroll.

3. **Budget spent tính từ getDashboard** — `getBudgetStatuses()` và `checkBudget()` đều gọi `getDashboard()` (load toàn bộ monthly transactions). Nên query trực tiếp Firestore aggregate.

4. **Firestore composite indexes** — Các query có `where` + `orderBy` trên khác field (ví dụ `wallet_id` + `date DESC`) cần composite index. Chưa có `firestore.indexes.json` cập nhật.

5. **QuickAddParser keyword learning chỉ in-memory** — `_learnedMap` mất khi restart app. Cần persist vào Firestore settings.

6. **Anonymous user data isolation** — Khi anonymous user upgrade to email, data vẫn ở account cũ. Nếu user logout rồi login lại, cần đảm bảo account ID được restore đúng.

7. **No Firestore security rules update** — Rules cũ (từ SQLite sync era) chưa được cập nhật cho schema mới (budgets, activities, invites collections).

8. **setState sau dispose** — Một số screen gọi async rồi `setState` mà chỉ check `mounted` ở một số chỗ.

9. **Test coverage thấp** — 7 test files chỉ cover utils, models, enum, parser. Không có test cho services, repositories, hoặc widget tests.

10. **Currency conversion chưa có** — Khi wallets có mixed currencies, tổng balance không thể tính. Cần exchange rate API hoặc static rates.

11. **No push notification** — Family members không nhận notification khi được invite hoặc khi có transaction mới.

12. **Error messages hiển thị raw exception** — Firestore errors hiển thị nguyên văn, cần map sang user-friendly messages.
