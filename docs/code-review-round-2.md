# Code Review Round 2 — Vintage Ledger

> Ngày: Tháng 7/2025 | Phiên bản: 0.0.1+1 | 69 file Dart | ~5.700 dòng code
> So với Round 1: +6 file mới (widgets, mixin, service_locator, tests), -2 file xóa (dead code)

---

## 1. Tổng quan sau refactor

**Điểm tổng: 8.5/10** (lên từ 7.5)

| Tiêu chí | R1 | R2 | Ghi chú |
|---|---|---|---|
| Kiến trúc & tổ chức | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Giữ nguyên, feature-first tốt |
| Chất lượng code | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | DI, error handling, no dead code |
| UI/UX consistency | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | AsyncContent, loading states |
| Data layer | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Atomic transactions, indexes, FK |
| Tái sử dụng code | ⭐⭐⭐ | ⭐⭐⭐⭐ | Mixin, shared widgets, DashboardData |
| Testing | ⭐ | ⭐⭐ | Có unit test cho formatters |
| Error handling | ⭐⭐ | ⭐⭐⭐⭐ | try-catch ở Home, WalletDetail |
| Scalability | ⭐⭐⭐ | ⭐⭐⭐⭐ | ServiceLocator, CrudListMixin |

---

## 2. Tổ chức code (Folder & File Structure)

### 2.1 Đã tốt

```
lib/
├── core/           ← Infra: DB, theme, l10n, constants, DI
├── common/         ← Shared widgets + mixins
├── features/       ← Feature-first modules
│   ├── auth/       ← models/ → repos/ → services/ → screens/
│   ├── category/
│   ├── transaction/
│   ├── wallet/
│   ├── settings/
│   └── onboarding/
├── utils/          ← Pure helpers (formatters, extensions)
└── main.dart
```

- Feature-first structure nhất quán: mỗi feature có `models/`, `repositories/`, `services/`, `screens/`, `widgets/`.
- `core/` tách biệt rõ ràng infra (DB, theme, l10n) khỏi business logic.
- `common/widgets/` chứa 16 reusable widgets — tỷ lệ reuse cao.
- `utils/` chỉ chứa pure functions, không phụ thuộc Flutter widgets.

### 2.2 Vấn đề còn lại

#### `home_screen.dart` nằm lạc chỗ
`lib/features/home_screen.dart` nằm trực tiếp trong `features/` thay vì trong một feature folder. Nó là screen chính nhưng không thuộc feature nào cụ thể.

**Khuyến nghị:** Chuyển vào `features/home/screens/home_screen.dart` hoặc giữ nguyên nhưng tạo `features/home/` folder cho consistency.

#### `DashboardData` nằm trong `TransactionService`
`DashboardData` class được định nghĩa cùng file với `TransactionService`. Nó là data model dùng ở nhiều screen nhưng nằm trong service file.

**Khuyến nghị:** Tách ra `features/transaction/models/dashboard_data.dart` hoặc `common/models/dashboard_data.dart`.

#### `onboarding/` không theo cấu trúc feature chuẩn
`onboarding/` chỉ có 2 file (`welcome_screen.dart`, `sample_data_service.dart`) nằm trực tiếp trong folder, không có `screens/` hay `services/` subfolder.

**Khuyến nghị:** Nhỏ nên chấp nhận được. Nếu muốn consistency thì tách thành `screens/` + `services/`.

#### `SampleDataService` không dùng `sl`
`SampleDataService` tạo `WalletService()`, `TransactionService()`, `CategoryService()` trực tiếp thay vì dùng `sl`.

#### `WalletService` tạo `TransactionService()` nội bộ
`WalletService` có `final TransactionService _transactionService = TransactionService()` — tạo instance riêng thay vì dùng `sl`. Tương tự `TransactionService` tạo repositories nội bộ.

**Khuyến nghị:** Hoặc inject qua constructor, hoặc dùng `sl` trong service layer. Hiện tại DI chỉ áp dụng ở screen layer, chưa xuyên suốt.

---

## 3. Design Patterns

### 3.1 Đã áp dụng tốt

| Pattern | Nơi dùng | Đánh giá |
|---|---|---|
| Repository Pattern | Mỗi feature có repository tách biệt DB access | ✅ |
| Service Layer | Business logic tách khỏi UI và DB | ✅ |
| Singleton (DB) | `AppDatabase.instance` | ✅ |
| Singleton (DI) | `ServiceLocator.instance` / `sl` | ✅ |
| Mixin | `CrudListMixin` cho list screens | ✅ |
| Master Page | `AppScaffold` + `LedgerHeader` | ✅ |
| Design Tokens | `AppColors`, `AppTextStyles`, `AppSpacing` | ✅ |

### 3.2 Vấn đề

#### Không có state management pattern
Toàn bộ app dùng `setState()` trực tiếp. Với quy mô hiện tại (~5.700 LOC) thì chấp nhận được, nhưng:
- Không có cách share state giữa screens (ví dụ: wallet list thay đổi → home screen không biết cho đến khi pop back + reload)
- `_amountVisible` state ở `HomeScreen` mất khi navigate away

#### Models thiếu `copyWith`, `==`, `hashCode`
`Wallet`, `TransactionModel`, `Category` chỉ có `toMap`/`fromMap`. Không có:
- `copyWith()` — phải tạo object mới thủ công mỗi lần update
- `==` / `hashCode` — không thể so sánh 2 object cùng data
- `toString()` — debug khó

#### Transaction type dùng String magic
`type` field dùng `'income'` / `'expense'` string literals rải rác khắp codebase. Nếu typo → bug silent.

**Khuyến nghị:** Dùng enum:
```dart
enum TransactionType { income, expense }
```

---

## 4. Tái sử dụng code

### 4.1 Cải thiện so với Round 1

| Metric | R1 | R2 |
|---|---|---|
| Shared widgets | 12 | 18 (+6: AsyncContent, LedgerListTile, FormSaveButton, IncomeExpenseSummaryRow, DeleteConfirmation, NavigatorX) |
| Confirm delete implementations | 4 copy-paste | 1 shared function |
| Navigation boilerplate | 15+ chỗ full code | Dùng `context.pushScreen()` |
| List screen state logic | Copy-paste | `CrudListMixin` |
| Dashboard load logic | 2 chỗ trùng 80% | 1 `getDashboard()` |
| TransactionSection callbacks | 3 callbacks | 1 `onDataChanged` |

### 4.2 Vấn đề còn lại

#### `TransactionListScreen` không dùng `CrudListMixin`
`WalletListScreen` và `CategoryListScreen` đã dùng mixin, nhưng `TransactionListScreen` vẫn tự quản lý state riêng (vì nó có lazy loading, grouping — phức tạp hơn). Chấp nhận được.

#### `_buildWalletCard` và `_buildAddWalletCard` trong HomeScreen
2 widget builder methods chỉ dùng ở HomeScreen, inline ~40 dòng mỗi cái. Nếu cần reuse ở nơi khác thì phải extract.

#### `ChartSection` tính toán data trong widget
`_dailyData`, `_expenseByCategory`, `_totalByType` tính trực tiếp trong `ChartSection` widget. Nếu data lớn → rebuild chậm. Nên tính sẵn trong `DashboardData` hoặc cache.

---

## 5. Database Design

### 5.1 Đã tốt sau refactor

- ✅ `PRAGMA foreign_keys = ON`
- ✅ Foreign keys cho `transactions` (wallet_id, category_id) và `transaction_items` (transaction_id)
- ✅ Indexes trên `wallet_id`, `date`, `transaction_id`
- ✅ `date INTEGER` thay vì `TEXT`
- ✅ Atomic transactions cho create/update/delete
- ✅ `recalculateBalance()` utility
- ✅ DB version migration (`onUpgrade`)

### 5.2 Vấn đề còn lại

#### Không có `ON DELETE` action cho transactions → wallets/categories
```sql
FOREIGN KEY(wallet_id) REFERENCES wallets(id),        -- không có ON DELETE
FOREIGN KEY(category_id) REFERENCES categories(id),   -- không có ON DELETE
```
Nếu xóa wallet/category mà còn transactions tham chiếu → FK violation error. Code hiện tại xử lý bằng `WalletService.deleteWallet` (xóa transactions trước), nhưng nếu gọi trực tiếp `WalletRepository.delete` → crash.

**Khuyến nghị:** Thêm `ON DELETE CASCADE` cho wallet_id, `ON DELETE SET NULL` hoặc `ON DELETE RESTRICT` cho category_id.

#### `created_at` trong wallets lưu ISO string, `date` trong transactions lưu epoch int
Hai convention khác nhau cho datetime trong cùng DB. Nên thống nhất.

#### Không có `updated_at` timestamp
Không track khi nào record được sửa lần cuối. Hữu ích cho sync, audit, conflict resolution.

#### `amount` lưu kiểu `INTEGER` không có constraint
```sql
amount INTEGER,  -- có thể null, có thể âm
```
Service validate `amount > 0` nhưng DB không enforce. Nên thêm `NOT NULL CHECK(amount > 0)`.

#### `type` column không có CHECK constraint
```sql
type TEXT,  -- có thể là bất kỳ string nào
```
Nên thêm `CHECK(type IN ('income', 'expense'))`.

#### `deleteAllByWallet` không atomic
`TransactionRepository.deleteAllByWallet` xóa items rồi transactions trong 2 queries riêng, không wrap trong `db.transaction()`. Nếu fail giữa chừng → orphan data.

---

## 6. Vấn đề khác

### 6.1 Test coverage thấp
Chỉ có test cho `AmountFormatter` và `DateFormatter` (pure functions). Không có:
- Service tests (cần mock DB)
- Widget tests
- Integration tests

### 6.2 `WalletFormScreen` có inline `floatingLabelBehavior` và `border`
```dart
decoration: InputDecoration(
  floatingLabelBehavior: FloatingLabelBehavior.always,  // đã set trong theme
  border: const OutlineInputBorder(),                    // đã set trong theme
),
```
Vi phạm style guide rule: "No inline FloatingLabelBehavior" và input border đã config trong `InputDecorationTheme`.

### 6.3 `AppTextStyles` fields không phải `const`
Hầu hết fields trong `AppTextStyles` là `static TextStyle` (non-const) vì dùng `copyWith()`. Mỗi lần access tạo object mới. Với Flutter rebuild frequency → nhiều allocations không cần thiết.

### 6.4 `TransactionListScreen` không có error handling
`_initialLoad`, `_loadMonth` không có try-catch. Nếu DB lỗi → crash. Các screen khác (Home, WalletDetail) đã fix nhưng screen này chưa.

### 6.5 `SampleDataService` tạo transactions tuần tự
`generate()` tạo ~60-90 transactions bằng vòng lặp `await` tuần tự. Mỗi transaction = 1 DB transaction. Có thể batch insert để nhanh hơn.

---

## 7. Kết luận

Codebase đã cải thiện đáng kể sau Round 1:
- **DB layer** từ yếu → mạnh (atomic, FK, indexes, migration)
- **Reusability** từ widget-level → screen-level (mixin, shared data, DI)
- **Error handling** từ không có → có ở các screen chính

Các vấn đề còn lại chủ yếu ở mức **polish**: thống nhất convention (datetime format, DI xuyên suốt), thêm DB constraints, mở rộng test coverage, và chuẩn bị cho scale (state management, enum types).
