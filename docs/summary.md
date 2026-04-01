# Vintage Ledger — Summary v0.0.1

> Ứng dụng quản lý thu chi cá nhân & gia đình, phong cách vintage, xây dựng bằng Flutter.
> 78 files Dart · ~7,600 LOC · 6 test files

---

## Kiến trúc tổng quan

- **Pattern**: Feature-first (Repository → Service → Screen)
- **Local DB**: SQLite (sqflite) — 6 tables, version 1, clean schema
- **Cloud**: Firebase Auth + Cloud Firestore
- **Sync**: Local-first, user-triggered, last-write-wins conflict resolution
- **DI**: ServiceLocator singleton (`sl`)
- **State**: AppState (currentUserId, currentAccountId)
- **L10n**: Vietnamese (mặc định) / English, key-based `S.of(context, 'key')`
- **Theme**: Vintage — 2 fonts (SpecialElite, PatrickHand), paper background, ink colors

---

## Tính năng chi tiết

### 1. Xác thực (Auth)

| Tính năng | Mô tả |
|---|---|
| Đăng nhập | Email + password qua Firebase Auth |
| Đăng ký | Email + password + display name, tự tạo personal account trên Firestore |
| Bỏ qua đăng nhập | Dùng offline với account `local`, data lưu SQLite |
| Đăng xuất | Xóa session, quay về LoginScreen |
| Migrate data | Khi login lần đầu, data local được chuyển sang account online |
| Auto-import | Nếu login mà local trống, tự sync từ cloud về |

### 2. Hệ thống Account

| Tính năng | Mô tả |
|---|---|
| Personal account | Tạo tự động khi đăng ký, 1 user = 1 personal account |
| Family account | Tạo thủ công, chia sẻ data giữa nhiều thành viên |
| Unified schema | Personal và family dùng chung schema `accounts/{accountId}/` trên Firestore |
| Chọn account | AccountPickerScreen hiển thị tất cả accounts, tap để chọn |
| Auto-sync khi chọn | Tự động sync khi chọn account để pull data mới nhất |

### 3. Quản lý gia đình (Family)

| Tính năng | Mô tả |
|---|---|
| Tạo gia đình | Nhập tên, tự seed categories |
| Mời thành viên | Nhập email, tìm user trên Firestore, thêm vào member_ids |
| Xóa thành viên | Owner có thể remove member |
| Rời gia đình | Member tự rời, nếu owner rời thì chuyển quyền hoặc xóa |
| Xóa gia đình | Owner xóa toàn bộ (subcollections + account doc) |
| Chi tiết gia đình | Xem danh sách members với role (owner/member), long-press từ AccountPicker |

### 4. Quản lý ví (Wallet)

| Tính năng | Mô tả |
|---|---|
| Tạo ví | Nhập tên + số dư ban đầu |
| Sửa ví | Đổi tên, chỉnh số dư |
| Xóa ví | Swipe-to-delete với confirm dialog, cascade xóa transactions |
| Danh sách ví | Pull-to-refresh, swipe actions |
| Chi tiết ví | Hiển thị số dư, biểu đồ tháng, giao dịch gần đây |
| Số dư tự động | Balance được tính atomic khi tạo/sửa/xóa transaction |
| Recalculate | Hàm recalculateBalance cho sync pull |

### 5. Quản lý giao dịch (Transaction)

| Tính năng | Mô tả |
|---|---|
| Tạo giao dịch | Chọn loại (thu/chi), ví, danh mục, số tiền, ngày giờ, ghi chú |
| Sửa giao dịch | Revert balance cũ → apply balance mới (atomic) |
| Xóa giao dịch | Revert balance + xóa items + log sync_deletes (atomic) |
| Mục chi tiết | Transaction items — chia nhỏ 1 giao dịch thành nhiều mục |
| Validation | Amount > 0, tổng items ≤ amount, wallet required |
| Lazy loading | TransactionListScreen load theo tháng, scroll thêm tự động |
| Nhóm giao dịch | Group by ngày / tuần / tháng với tổng thu chi mỗi nhóm |
| Giao dịch gần đây | TransactionSection trên Home và WalletDetail, giới hạn 5 |

### 6. Quản lý danh mục (Category)

| Tính năng | Mô tả |
|---|---|
| Tạo danh mục | Nhập tên, chọn loại (thu/chi), chọn icon từ Material Icons |
| Sửa danh mục | Đổi tên, loại, icon |
| Xóa danh mục | Swipe-to-delete, RESTRICT nếu có transaction đang dùng |
| Seed mặc định | 14 categories (10 chi + 4 thu) khi tạo DB local |
| Seed Firestore | 9 categories khi tạo account (personal/family) |
| Lọc theo loại | CategoryDropdown trong form giao dịch lọc theo income/expense |
| Tạo nhanh | Nút "+" trong CategoryDropdown để tạo category mới ngay trong form |

### 7. Biểu đồ (Charts)

| Tính năng | Mô tả |
|---|---|
| Trend chart | Line chart thu/chi theo ngày trong tháng (fl_chart) |
| Daily chart | Bar chart so sánh thu/chi từng ngày |
| Breakdown chart | Pie chart tỷ lệ chi theo danh mục |
| Summary view | Tổng thu, tổng chi, chênh lệch, số giao dịch, ngày chi nhiều nhất |
| Legend | Chú thích màu cho từng loại biểu đồ |
| Animated switch | Chuyển đổi giữa các view với animation |

### 8. Đồng bộ (Sync)

| Tính năng | Mô tả |
|---|---|
| Push | Đẩy records dirty (is_synced=0) lên Firestore, batch update + individual add |
| Pull | Kéo records mới từ Firestore (incremental by updated_at), upsert vào SQLite |
| Tombstone delete | Xóa local → log sync_deletes → push set deleted_at trên Firestore → device khác pull thấy deleted_at → xóa local |
| Last-write-wins | Conflict resolution: local newer + dirty → giữ local, ngược lại → overwrite |
| Cross-device ID mapping | Push: local wallet_id/category_id → remote_id. Pull: remote_id → local id |
| Embedded items | Transaction items được embed trong transaction doc trên Firestore |
| Dirty count badge | Dot đỏ trên icon swap_horiz ở HomeScreen khi có records chưa sync |
| Sync all | AccountPickerScreen sync tất cả accounts |
| Sync account | SettingScreen sync account hiện tại |
| Auto-sync | Tự sync khi chọn account từ AccountPicker |
| Tombstone cleanup | Xóa tombstones > 30 ngày trên Firestore, tối đa 1 lần/ngày |
| Network check | Kiểm tra connectivity trước khi sync |
| Lần đồng bộ cuối | Hiển thị trong SettingScreen |

### 9. Màn hình chính (Home)

| Tính năng | Mô tả |
|---|---|
| Balance card | Tổng số dư tất cả ví, tap để ẩn/hiện số tiền |
| Thu chi tháng | Tổng thu và tổng chi tháng hiện tại |
| Wallet row | Horizontal scroll danh sách ví + nút thêm ví |
| Chart section | Biểu đồ tháng hiện tại |
| Recent transactions | 5 giao dịch gần đây dạng bảng |
| FAB | Nút thêm giao dịch nhanh |
| Pull-to-refresh | Kéo xuống để reload toàn bộ data |
| Account switcher | Icon ↔ để quay về AccountPickerScreen (chỉ khi đã login) |

### 10. Cài đặt (Settings)

| Tính năng | Mô tả |
|---|---|
| Thông tin tài khoản | Hiển thị email, display name |
| Đăng xuất | Xóa session Firebase Auth |
| Đồng bộ ngay | Trigger sync cho account hiện tại |
| Lần đồng bộ cuối | Timestamp lần pull gần nhất |
| Chuyển ngôn ngữ | Vietnamese / English, lưu vào SQLite settings |

### 11. Đa ngôn ngữ (L10n)

| Tính năng | Mô tả |
|---|---|
| Vietnamese (mặc định) | ~120 keys |
| English | ~120 keys |
| Locale toggle | Widget chuyển ngôn ngữ trên LoginScreen |
| Runtime switch | Đổi ngôn ngữ trong Settings, apply ngay không cần restart |

### 12. UI/UX

| Tính năng | Mô tả |
|---|---|
| Vintage theme | Paper background, ink colors, SpecialElite + PatrickHand fonts |
| AppScaffold | Scaffold wrapper với LedgerHeader (vintage AppBar + divider) |
| LedgerCard | Card container với border, shadow, border-radius 12 |
| AmountText | Hiển thị số tiền có màu (xanh = thu, đỏ = chi), hỗ trợ compact format |
| SwipeListItem | Swipe-to-delete với confirm dialog |
| AsyncContent | Loading/error/content wrapper |
| EmptyState | Placeholder text cho danh sách trống |
| FormSaveButton | Nút Lưu/Cập nhật thống nhất |
| DeleteConfirmation | Dialog xác nhận xóa dùng chung |
| AmountInputField | Input số tiền với keypad |
| TypeSelector | Toggle income/expense |
| CrudListMixin | Mixin cho list screens (load, delete, confirm, openForm) |

---

## Database Schema (SQLite v1)

| Table | Columns chính | Ghi chú |
|---|---|---|
| `settings` | key (PK), value | Lưu locale, sync timestamps |
| `wallets` | id, name, balance, created_at, updated_at, account_id, is_synced, remote_id | Balance auto-calculated |
| `categories` | id, name, type, icon, created_at, updated_at, account_id, is_synced, remote_id | type = income/expense |
| `transactions` | id, wallet_id (FK), category_id (FK), type, amount, note, date, updated_at, account_id, is_synced, remote_id, created_by | CHECK(type IN), CHECK(amount > 0) |
| `transaction_items` | id, transaction_id (FK), amount, category_id, note | CASCADE delete |
| `sync_deletes` | id, table_name, remote_id, account_id, deleted_at | Tombstone log |

6 composite indexes cho performance.

---

## Firestore Schema

```
accounts/{accountId}/
  ├── wallets/{docId}     → name, created_at, updated_at, [deleted_at]
  ├── transactions/{docId} → wallet_id, category_id, type, amount, note, date, created_by, updated_at, items[], [deleted_at]
  └── categories/{docId}   → name, type, icon, created_at, updated_at, [deleted_at]

users/{userId}/
  → email, display_name, account_ids[], created_at
```

Security rules: chỉ members trong `member_ids` mới đọc/ghi được subcollections.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Local DB | SQLite (sqflite + sqflite_common_ffi) |
| Cloud DB | Cloud Firestore |
| Auth | Firebase Auth (email/password) |
| Charts | fl_chart |
| Fonts | SpecialElite, PatrickHand (bundled) |
| Swipe actions | flutter_slidable |
| Network check | connectivity_plus |
| L10n | flutter_localizations + custom S helper |

---

## Known Issues

1. **DropdownButtonFormField dùng `initialValue` thay vì `value`** — `_buildWalletDropdown()` trong `transaction_form_screen.dart` dùng `initialValue` (không phải API chuẩn của Flutter), có thể gây lỗi compile hoặc không reactive khi state thay đổi.

2. **Push categories thiếu `created_at`** — `_pushCollection` gửi tất cả fields trừ `id`, `remote_id`, `is_synced`, `account_id`, `balance`. Nhưng `created_at` được gửi lên, nếu Firestore doc đã có `created_at` thì sẽ bị overwrite mỗi lần push (nên chỉ gửi khi tạo mới).

3. **Transaction push không gửi `created_at`** — Table `transactions` không có `created_at` column (chỉ có `date` và `updated_at`), nhưng Firestore cũng không cần vì dùng `date` làm thời gian giao dịch.

4. **Pull transactions: items category_id không resolve** — Khi pull transaction items, `category_id` trong items vẫn là giá trị gốc (có thể là remote_id string), không được convert sang local id.

5. **Wallet balance không sync** — `_pushCollection` remove `balance` trước khi push (đúng vì balance là computed). Nhưng khi pull wallets, balance không được set → phải dựa vào `recalculateBalance`. Nếu pull wallets trước pull transactions, balance sẽ sai cho đến khi transactions được pull xong.

6. **Seed categories không đồng nhất** — Local seed 14 categories, Firestore seed 9 categories. Khi user tạo account mới và sync, sẽ có bộ categories khác nhau giữa local và cloud.

7. **`_maybeImportFromCloud` logic** — Chỉ import nếu `wallets.isEmpty`, nhưng sau `migrateLocalDataToAccount` có thể đã có wallets (từ local) → skip import → categories từ cloud không được pull.

8. **Không có error handling cho Firestore quota/permission** — Nếu Firestore rules deny hoặc quota hết, error message hiển thị raw Firebase exception.

9. **setState sau dispose** — Nhiều screen gọi async rồi `setState` mà chỉ check `mounted` ở một số chỗ, không phải tất cả.

10. **Test coverage thấp** — 6 test files chỉ cover utils, models, enum, upsert logic. Không có test cho services, repositories, hoặc widget tests.

11. **Không có retry/exponential backoff cho sync** — Nếu sync fail giữa chừng (ví dụ push xong nhưng pull fail), trạng thái có thể inconsistent.

12. **TransactionListScreen không filter theo accountId** — `_loadCategories` gọi `sl.categoryService.getCategories()` (đã filter theo accountId), nhưng nếu user switch account mà screen vẫn mở, data sẽ stale.

13. **Family account: không có notification khi được invite** — Member mới chỉ thấy account khi mở app và load lại danh sách accounts.

14. **Onboarding l10n keys còn sót** — `welcomeTitle`, `welcomeSubtitle`, `startWithSample`, `startEmpty` vẫn còn trong l10n nhưng không có screen nào dùng (đã xóa onboarding).
