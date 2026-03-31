# Đánh giá Codebase — Vintage Ledger

> Ngày đánh giá: Tháng 7/2025
> Phiên bản: 0.0.1+1 | Flutter (Dart) | ~63 file Dart | ~5.700 dòng code

---

## 1. Tổng quan

Vintage Ledger là ứng dụng quản lý thu chi cá nhân với giao diện phong cách vintage, hỗ trợ đa nền tảng (Android, iOS, Windows, Linux, macOS, Web). Codebase gọn gàng, tổ chức theo feature-first, tuân thủ tốt style guide riêng.

**Điểm tổng: 7.5/10**

| Tiêu chí | Điểm | Ghi chú |
|---|---|---|
| Kiến trúc & tổ chức | ⭐⭐⭐⭐ | Feature-first rõ ràng, tách layer tốt |
| Chất lượng code | ⭐⭐⭐⭐ | Sạch, nhất quán, ít code thừa |
| UI/UX consistency | ⭐⭐⭐⭐⭐ | Theme system mạnh, tuân thủ style guide |
| Data layer | ⭐⭐⭐ | Hoạt động tốt nhưng có rủi ro |
| Testing | ⭐ | Gần như không có test |
| Error handling | ⭐⭐ | Thiếu xử lý lỗi ở nhiều nơi |
| Scalability | ⭐⭐⭐ | Ổn cho app nhỏ, cần refactor nếu mở rộng |

---

## 2. Điểm mạnh

### 2.1 Kiến trúc feature-first rõ ràng
Mỗi feature (wallet, transaction, category, auth, settings) có cấu trúc `models/ → repositories/ → services/ → screens/ → widgets/` nhất quán. Dễ tìm code, dễ onboard developer mới.

### 2.2 Theme system xuất sắc
- `AppColors`, `AppTextStyles`, `AppSpacing` tập trung hoàn toàn — không có inline style rải rác.
- `AppTheme.light` cấu hình đầy đủ cho mọi widget Material (button, input, dialog, snackbar, tab, checkbox...).
- Hai font SpecialElite + PatrickHand tạo identity vintage rất nhất quán.

### 2.3 Localization đơn giản hiệu quả
`S.of(context, 'key')` — lightweight, không cần code generation, fallback về tiếng Việt khi thiếu key. Đủ dùng cho app 2 ngôn ngữ.

### 2.4 Reusable widgets tốt
`AppScaffold`, `LedgerCard`, `LedgerHeader`, `AmountText`, `SwipeListItem`, `TypeSelector`, `AmountInputField` + `AmountKeypad` — tất cả đều gọn, single-responsibility, dễ tái sử dụng.

### 2.5 Chart system đa dạng
4 loại chart (Trend, Daily, Breakdown, Summary) với `ChartStyles` mixin chia sẻ config chung. Animated transitions giữa các view.

### 2.6 AmountFormatter thông minh
Hỗ trợ compact format theo locale (vi: `1tr5`, `300k` | en: `1.5m`, `300k`), phù hợp văn hóa hiển thị tiền Việt.

---

## 3. Vấn đề cần cải thiện

### 3.1 🔴 Không có test
`test/widget_test.dart` là template mặc định của Flutter, không liên quan đến app. Không có unit test cho service/repository, không có widget test, không có integration test.

**Khuyến nghị:** Ưu tiên viết test cho:
- `TransactionService` (logic cập nhật balance khi tạo/sửa/xóa transaction)
- `AmountFormatter` (pure function, dễ test nhất)
- `WalletService.deleteWallet` (cascade delete)

### 3.2 🔴 Thiếu database transaction (atomicity)
`TransactionService.createTransaction` thực hiện 2 thao tác: update wallet balance + insert transaction. Nếu insert thất bại sau khi đã update balance → dữ liệu không nhất quán.

```dart
// Hiện tại (transaction_service.dart):
await _walletRepo.update(...);  // ✅ thành công
return await _repo.create(transaction);  // ❌ nếu fail → balance sai
```

**Khuyến nghị:** Wrap trong `db.transaction()` để đảm bảo atomicity:
```dart
final db = await AppDatabase.instance.database;
await db.transaction((txn) async {
  // update wallet + insert transaction trong cùng 1 DB transaction
});
```

Tương tự cho `updateTransaction`, `deleteTransaction`.

### 3.3 🟡 Service/Repository tạo instance mới mỗi lần dùng
Mỗi screen tự tạo `WalletService()`, `TransactionService()`, `CategoryService()`. Mỗi service lại tạo repository mới. Không có dependency injection.

```dart
// home_screen.dart
final WalletService walletService = WalletService();
final TransactionService transactionService = TransactionService();
final CategoryService categoryService = CategoryService();
```

**Vấn đề:**
- Không thể mock khi test
- Tạo nhiều instance không cần thiết
- Khó thay đổi implementation

**Khuyến nghị:** Dùng singleton pattern hoặc DI đơn giản (Provider, get_it).

### 3.4 🟡 N+1 query trong _attachItems
`TransactionService._attachItems` gọi `getByTransaction` cho từng transaction trong vòng lặp:

```dart
Future<List<TransactionWithItems>> _attachItems(List<TransactionModel> transactions) async {
  final result = <TransactionWithItems>[];
  for (var t in transactions) {
    final items = await _itemRepo.getByTransaction(t.id!);  // 1 query per transaction
    result.add(TransactionWithItems(transaction: t, items: items));
  }
  return result;
}
```

Với 30 transactions → 30 queries. **Khuyến nghị:** Batch load tất cả items bằng `WHERE transaction_id IN (...)` rồi group theo transaction_id.

### 3.5 🟡 Hardcode Vietnamese trong AuthService
```dart
String _reason() {
  if (Platform.isWindows) return "Xác thực bằng Windows Hello";
  return "Xác thực để mở ứng dụng";
}
```
`AuthService` không có `BuildContext` nên không dùng được `S.of()`. Chuỗi này hiển thị trong system dialog.

**Khuyến nghị:** Truyền `localizedReason` từ caller (LockScreen/AutoLockWrapper) thay vì hardcode.

### 3.6 🟡 Không xử lý lỗi ở UI layer
Hầu hết các screen gọi service mà không try-catch:

```dart
Future<void> loadData() async {
  final w = await walletService.getWallets();
  // Nếu DB lỗi → crash
  setState(() { wallets = w; });
}
```

**Khuyến nghị:** Wrap trong try-catch, hiển thị error state hoặc snackbar khi thất bại.

### 3.7 🟡 DropdownButtonFormField dùng `initialValue` thay vì `value`
Trong `transaction_form_screen.dart` và `category_dropdown.dart`:
```dart
DropdownButtonFormField<int>(
  initialValue: _walletId,  // ⚠️ không phải API chuẩn
```
`DropdownButtonFormField` dùng `value`, không phải `initialValue`. Có thể gây lỗi hoặc không reactive khi state thay đổi.

### 3.8 🟡 Icon code point mismatch
Trong `database.dart`, seed categories dùng hardcode code point:
```dart
{'name': 'Ăn uống', 'type': 'expense', 'icon': 0xe25a},  // fastfood
```
Nhưng trong `category_icons.dart`, `kCategoryIconMap` map code point khác:
```dart
0xe57a: Icons.fastfood,
```
Các code point không khớp nhau → icon hiển thị sai, fallback về `help_outline`.

**Khuyến nghị:** Dùng `Icons.fastfood.codePoint` trực tiếp khi seed, hoặc đồng bộ map.

### 3.9 🟢 Wallet balance lưu dư thừa (denormalized)
Balance được lưu trực tiếp trong bảng `wallets` và cập nhật thủ công mỗi khi tạo/sửa/xóa transaction. Nếu có bug → balance drift, không có cách tự sửa.

**Khuyến nghị:** Thêm function `recalculateBalance(walletId)` tính lại từ tổng transactions, dùng khi cần verify hoặc repair.

### 3.10 🟢 Thiếu index cho database
Bảng `transactions` query thường xuyên theo `wallet_id`, `date`, `category_id` nhưng không có index:

```sql
CREATE TABLE transactions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  wallet_id INTEGER,  -- không có index
  category_id INTEGER,
  type TEXT,
  amount INTEGER,
  date TEXT  -- không có index
)
```

**Khuyến nghị:** Thêm index cho các cột query thường xuyên:
```sql
CREATE INDEX idx_transactions_wallet ON transactions(wallet_id);
CREATE INDEX idx_transactions_date ON transactions(date);
```

### 3.11 🟢 `date` column lưu kiểu TEXT nhưng thực tế là INTEGER
Schema khai báo `date TEXT` nhưng code lưu `millisecondsSinceEpoch` (int). SQLite linh hoạt nên vẫn hoạt động, nhưng nên khai báo đúng kiểu `date INTEGER` cho rõ ràng.

### 3.12 🟢 Không có FOREIGN KEY enforcement
SQLite mặc định tắt foreign key. Bảng `transactions` tham chiếu `wallet_id`, `category_id` nhưng không khai báo `FOREIGN KEY`. Bảng `transaction_items` có khai báo nhưng thiếu `PRAGMA foreign_keys = ON`.

**Khuyến nghị:** Thêm `onConfigure` callback:
```dart
return await openDatabase(
  path,
  version: 1,
  onConfigure: (db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  },
  onCreate: _createDB,
);
```

---

## 4. Vấn đề nhỏ khác

| # | Vấn đề | File | Mức độ |
|---|---|---|---|
| 1 | `_resetOnInit` flag trong production code | `database.dart` | Thấp — nên dùng build config thay vì const |
| 2 | `PrimaryButton` widget không được sử dụng | `primary_button.dart` | Thấp — dead code |
| 3 | `CategorySection` widget không được sử dụng | `category_section.dart` | Thấp — dead code |
| 4 | `rename` package trong dependencies chính | `pubspec.yaml` | Thấp — nên chuyển sang dev_dependencies |
| 5 | `separatorBuilder: (_, _)` dùng wildcard pattern | `home_screen.dart` | Thấp — cần Dart 3.x, OK nếu đã target |
| 6 | `TransactionItemRepository.create` validate amount nhưng `update` cũng validate → logic trùng lặp | `transaction_item_repository.dart` | Thấp |
| 7 | `deleteTransaction` xóa items bằng vòng lặp thay vì batch delete | `transaction_service.dart` | Thấp |

---

## 5. Đề xuất cải tiến theo thứ tự ưu tiên

1. **Wrap DB operations trong transaction** — Tránh data inconsistency (balance sai)
2. **Thêm PRAGMA foreign_keys = ON** — Bảo vệ referential integrity
3. **Fix icon code point mismatch** — Sửa bug hiển thị icon sai
4. **Thêm database index** — Cải thiện performance khi data lớn
5. **Thêm error handling ở UI** — Tránh crash khi DB lỗi
6. **Viết unit test cho services** — Đảm bảo logic business đúng
7. **Batch load transaction items** — Giảm N+1 queries
8. **Dependency injection** — Dễ test, dễ maintain

---

## 6. Đánh giá UI/UX Consistency

### 6.1 Đã làm tốt

- Mọi screen đều dùng `AppScaffold` → header vintage nhất quán, không screen nào tự build Scaffold riêng.
- Không có inline `TextStyle()`, `Color()` nào — 100% dùng `AppTextStyles.*` và `AppColors.*`.
- `LedgerCard` dùng nhất quán cho mọi content block (balance card, chart, transaction section).
- `AmountText` xử lý tập trung logic hiển thị tiền (color theo type, format theo locale).
- `TypeSelector` (income/expense toggle) reuse giữa `TransactionFormScreen` và `CategoryFormScreen`.
- `AmountInputField` + `AmountKeypad` + `AmountPickerSheet` — bộ 3 input tiền tệ custom, reuse ở cả wallet form và transaction form.

### 6.2 Vấn đề UI/UX cần cải thiện

#### Không có loading state / error state chung

Mỗi screen tự xử lý loading/error theo cách riêng:

| Screen | Loading | Error | Empty |
|---|---|---|---|
| `HomeScreen` | ❌ Không có | ❌ Không có | Partial (`EmptyState` cho transaction) |
| `WalletListScreen` | ❌ Không có | ❌ Không có | ✅ `EmptyState` |
| `WalletDetailScreen` | ❌ Không có | ❌ Không có | ❌ Không có |
| `TransactionListScreen` | ✅ `CircularProgressIndicator` | ❌ Không có | ✅ Text |
| `CategoryListScreen` | ❌ Không có | ❌ Không có | ✅ Text (nhưng không dùng `EmptyState`) |

**Vấn đề:** Khi mở `HomeScreen` hoặc `WalletDetailScreen`, data load async nhưng UI render ngay với list rỗng → user thấy flash trống trước khi data xuất hiện.

**Khuyến nghị:** Tạo pattern loading/error/content chung, ví dụ:
```dart
class AsyncContent extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool isEmpty;
  final String emptyMessage;
  final Widget child;
  // ...
}
```

#### Confirm delete dialog copy-paste 4 lần

Cùng một pattern `showDialog<bool>` với title/content/cancel/delete được viết lại ở:
1. `WalletListScreen.confirmDelete()`
2. `CategoryListScreen.confirmDelete()`
3. `TransactionListScreen._confirmDelete()`
4. `TransactionSection` (inline trong `onLongPress`)

Mỗi chỗ chỉ khác `titleKey` và `contentKey`. **Khuyến nghị:** Extract thành helper:
```dart
Future<bool?> showDeleteConfirmation(BuildContext context, {required String titleKey, required String contentKey});
```

#### Inline BoxDecoration lặp lại

List item decoration (white background, borderRadius 12, shadow) xuất hiện giống hệt ở:
- `WalletListScreen` — wallet row
- `CategoryListScreen` — category row

```dart
// Copy-paste giống nhau ở cả 2 file:
decoration: BoxDecoration(
  color: Colors.white,        // ⚠️ Không dùng AppColors.paper
  borderRadius: BorderRadius.circular(12),
  boxShadow: [
    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
  ],
),
```

**Vấn đề kép:**
1. Dùng `Colors.white` thay vì `AppColors.paper` → vi phạm style guide
2. Decoration lặp lại mà không extract

**Khuyến nghị:** Tạo `LedgerListTile` widget hoặc thêm variant cho `LedgerCard`.

#### Income/Expense summary row lặp lại

Pattern "2 cột chia bởi divider dọc" xuất hiện ở:
1. `HomeScreen._buildBalanceCard()` — monthIncome | monthExpense
2. `TransactionListScreen._buildSummaryCard()` — totalIncome | totalExpense
3. `SummaryView` — tương tự nhưng dạng dọc

Có thể extract thành `IncomExpenseSummaryRow(income:, expense:)`.

---

## 7. Đánh giá Reusability & Base Patterns

### 7.1 Có gì đang reuse tốt?

| Component | Dùng ở | Đánh giá |
|---|---|---|
| `AppScaffold` | Mọi screen (8/8) | ✅ Master page pattern — tốt |
| `LedgerHeader` | Qua `AppScaffold` | ✅ Consistent AppBar |
| `LedgerCard` | Home, WalletDetail, TransactionList, ChartSection | ✅ Content container chuẩn |
| `AmountText` | 7+ nơi | ✅ Single source of truth cho hiển thị tiền |
| `SwipeListItem` | WalletList, CategoryList, TransactionList | ✅ Swipe-to-delete pattern |
| `EmptyState` | 4 nơi | ✅ Nhưng không phải chỗ nào cũng dùng (xem bên dưới) |
| `TypeSelector` | TransactionForm, CategoryForm | ✅ Income/expense toggle |
| `AmountInputField` | WalletForm, TransactionForm | ✅ Custom keypad input |
| `ChartSection` | Home, WalletDetail | ✅ Chart reuse tốt |
| `TransactionSection` | Home, WalletDetail | ✅ Recent transactions reuse tốt |

### 7.2 Thiếu gì?

#### ❌ Không có base class cho List Screen

`WalletListScreen`, `CategoryListScreen`, `TransactionListScreen` có cấu trúc gần giống nhau:

```
AppScaffold
  └─ RefreshIndicator
       └─ isEmpty ? EmptyState : ListView
            ├─ ...items.map(SwipeListItem(...))
            └─ ElevatedButton.icon("Thêm ...")
```

State logic cũng giống:
```dart
List<T> items = [];
initState() → loadItems();
Future<void> loadItems() async { ... setState(() => items = list); }
Future<void> deleteItem(int id) async { ... loadItems(); }
Future<bool?> confirmDelete() { ... showDialog ... }
Future<void> openForm({T? item}) async { ... Navigator.push ... if (result) loadItems(); }
```

**Mức độ trùng lặp:** ~60-70% code giữa `WalletListScreen` và `CategoryListScreen`.

**Khuyến nghị:** Tạo `CrudListScreen<T>` hoặc ít nhất extract phần state management:

```dart
// Option A: Mixin cho state logic
mixin CrudListMixin<T> on State {
  List<T> items = [];
  Future<List<T>> fetchItems();
  Future<void> deleteItem(int id);
  // ...
}

// Option B: Generic list widget
class CrudListView<T> extends StatelessWidget {
  final List<T> items;
  final String emptyMessage;
  final String addLabel;
  final Widget Function(T item) itemBuilder;
  final VoidCallback onAdd;
  final Future<void> Function(T item) onDelete;
  // ...
}
```

#### ❌ Không có base class cho Form Screen

`WalletFormScreen`, `CategoryFormScreen`, `TransactionFormScreen` cùng pattern:

```
AppScaffold(title: isEdit ? 'Sửa ...' : 'Thêm ...')
  └─ Form(key: _formKey)
       └─ ListView
            ├─ ...fields
            └─ ElevatedButton(onPressed: save, child: Text('Lưu'))
```

State logic:
```dart
bool isEdit = false;
initState() → if (widget.item != null) { isEdit = true; populate fields; }
Future<void> save() async {
  if (!_formKey.currentState!.validate()) return;
  if (isEdit) await service.update(...);
  else await service.create(...);
  Navigator.pop(context, true);
}
```

**Khuyến nghị:** Không cần base class phức tạp, nhưng nên extract:
- `FormSaveButton` — full-width ElevatedButton với text "Lưu"/"Cập nhật" tự động theo isEdit
- Pattern `Navigator.pop(context, true)` sau save → có thể wrap thành helper

#### ❌ Không có base class cho Detail Screen

`HomeScreen` và `WalletDetailScreen` gần giống nhau:

```
AppScaffold
  └─ ListView
       ├─ LedgerCard(BalanceInfo)
       ├─ LedgerCard(ChartSection)
       └─ LedgerCard(TransactionSection)
```

State logic:
```dart
List<TransactionWithItems> recentTransactions = [];
List<TransactionWithItems> monthTransactions = [];
Map<int, Category> categoryMap = {};

Future<void> loadData() async {
  // load wallets/transactions/categories
  // build categoryMap
  setState(...);
}
```

**Mức độ trùng lặp:** `loadData()` logic gần giống 80% giữa `HomeScreen` và `WalletDetailScreen` (chỉ khác walletId filter).

**Khuyến nghị:** Extract `loadData` logic vào service hoặc tạo shared data holder:
```dart
class DashboardData {
  final List<TransactionWithItems> recent;
  final List<TransactionWithItems> monthly;
  final Map<int, Category> categoryMap;
  final int balance;
}

// Trong service:
Future<DashboardData> getDashboard({int? walletId});
```

#### ❌ Navigation boilerplate lặp lại

Pattern `Navigator.push → MaterialPageRoute → if (result == true) loadData()` xuất hiện **15+ lần** trong codebase. Mỗi lần đều viết đầy đủ:

```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SomeScreen(...)),
);
if (result == true) loadData();
```

**Khuyến nghị:** Helper extension:
```dart
extension NavigatorX on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) {
    return Navigator.push<T>(this, MaterialPageRoute(builder: (_) => screen));
  }
}
```

#### ❌ `TransactionSection` callback hell

`TransactionSection` nhận 3 callback functions:
```dart
TransactionSection(
  onAddTransaction: ...,
  onTapTransaction: (txn) async { Navigator.push(...); loadData(); },
  onDeleteTransaction: (txn) async { service.delete(...); loadData(); },
)
```

Cả `HomeScreen` và `WalletDetailScreen` đều truyền callback gần giống nhau (chỉ khác `loadData` reference). Nếu thêm screen thứ 3 dùng `TransactionSection` → lại copy-paste.

**Khuyến nghị:** `TransactionSection` nên tự handle navigation/delete internally, chỉ cần nhận `walletId` và callback `onDataChanged`.

### 7.3 Tổng kết Reusability

```
                    Reuse Level
                    
Theme/Styling       ████████████████████  100%  ← Xuất sắc
Common Widgets      ██████████████░░░░░░   70%  ← Tốt, nhưng thiếu vài widget chung
Screen Patterns     ████░░░░░░░░░░░░░░░░   20%  ← Yếu — không có base screen
State Management    ███░░░░░░░░░░░░░░░░░   15%  ← Yếu — mỗi screen tự quản lý
Navigation          ██░░░░░░░░░░░░░░░░░░   10%  ← Yếu — boilerplate lặp lại
```

### 7.4 Roadmap đề xuất

**Phase 1 — Quick wins (ít effort, nhiều impact):**
1. Extract `showDeleteConfirmation()` helper → giảm ~60 dòng trùng lặp
2. Extract `LedgerListTile` widget → fix style guide violation + giảm trùng lặp
3. Tạo `NavigatorX` extension → giảm boilerplate navigation
4. Thêm `AsyncContent` widget cho loading/error/empty states

**Phase 2 — Medium effort:**
5. Tạo `DashboardData` + service method → giảm trùng `loadData()` giữa Home và WalletDetail
6. Refactor `TransactionSection` để tự handle navigation → giảm callback hell
7. Extract `FormSaveButton` + `isEdit` pattern

**Phase 3 — Nếu app mở rộng thêm:**
8. Tạo `CrudListScreen<T>` generic hoặc mixin
9. State management solution (Provider/Riverpod) thay vì setState
10. Router package thay vì Navigator.push thủ công

---

## 8. Kết luận

Vintage Ledger là một codebase sạch, có tổ chức tốt cho một dự án cá nhân. Theme system và UI consistency ở tầng styling là điểm nổi bật — không có inline style nào, mọi thứ đi qua design tokens.

Tuy nhiên, reusability dừng ở mức **widget-level** (LedgerCard, AmountText, SwipeListItem...) mà chưa lên được **screen-level** (base list screen, base form screen, shared state patterns). Các screen có cấu trúc giống nhau 60-70% nhưng mỗi cái viết lại từ đầu → khi thêm feature mới sẽ tiếp tục copy-paste.

Với ~5.700 dòng code hiện tại, đây là thời điểm tốt để extract các pattern chung trước khi codebase phát triển lớn hơn. Ưu tiên Phase 1 (quick wins) sẽ giảm ngay ~150-200 dòng trùng lặp mà không cần refactor lớn.
