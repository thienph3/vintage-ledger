# Code Review Round 3 — Vintage Ledger

> Ngày: Tháng 7/2025 | 71 file Dart | ~5.900 LOC | 5 test files
> So với Round 1 (63 files, 5.700 LOC): +8 files, +200 LOC, +5 test files

---

## 1. Điểm tổng: 9/10 (R1: 7.5 → R2: 8.5 → R3: 9)

| Tiêu chí | R1 | R2 | R3 | Ghi chú |
|---|---|---|---|---|
| Kiến trúc & tổ chức | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Feature-first chuẩn, home/ + onboarding/ đã tách |
| Data layer | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | FK, CHECK, indexes, atomic, updated_at |
| Tái sử dụng | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Mixin, DI, DashboardData, cached chart |
| Type safety | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | TransactionType enum, copyWith, == |
| Testing | ⭐ | ⭐⭐ | ⭐⭐⭐ | 5 test files, ~35 test cases |
| Error handling | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Giữ nguyên, đã đủ cho app hiện tại |
| UI/UX consistency | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Không thay đổi, vẫn xuất sắc |

---

## 2. Cải thiện nổi bật so với Round 2

- **TransactionType enum** xuyên suốt — không còn string magic `'income'`/`'expense'` rải rác
- **DashboardData pre-computed** — chart data tính 1 lần khi tạo, không rebuild mỗi frame
- **Models có copyWith/==/hashCode** — type-safe, debug-friendly
- **DB v4** — `updated_at` column, sẵn sàng cho audit/sync
- **Batch insert** — SampleDataService nhanh hơn ~60x (1 batch thay 60-90 transactions riêng)
- **Folder structure chuẩn** — `home/screens/`, `onboarding/screens/` + `services/`

---

## 3. Vấn đề phát hiện

### 3.1 🔴 Syntax error trong `_onUpgrade` (database.dart)

```dart
if (oldVersion < 3) {
    await _migrateToV3(db);
if (oldVersion < 4) {          // ← thiếu closing brace }
    await _migrateToV4(db);
}
```

Thiếu `}` đóng block `if (oldVersion < 3)`. Sẽ gây compile error.

### 3.2 🔴 `import 'dart:io'` không dùng trong database.dart

`database.dart` import `dart:io` nhưng không sử dụng (đã xóa `_resetOnInit` flag ở round trước). Dead import.

### 3.3 🟡 `AmountText.type` vẫn là `String`

Mặc dù `TransactionModel.type` đã chuyển sang `TransactionType` enum, `AmountText` widget vẫn nhận `type` là `String`. Các caller phải gọi `.type.value` hoặc truyền literal `'income'`/`'expense'`. Nên chuyển sang nhận `TransactionType` hoặc tạo factory.

### 3.4 🟡 `CategoryFormScreen.initialType` vẫn là `String?`

`CategoryFormScreen` nhận `initialType` là `String?` thay vì `TransactionType?`. Chưa đồng bộ với enum migration.

### 3.5 🟡 `Category.type` vẫn là `String?`

Category model dùng `String?` cho `type` field. Nên dùng `TransactionType?` cho consistency, hoặc ít nhất validate khi fromMap.

### 3.6 🟡 `updated_at` chưa được set ở đâu

Column `updated_at` đã thêm vào schema nhưng không có code nào set giá trị. `TransactionService.updateTransaction` và `WalletService.updateWallet` không ghi `updated_at`.

### 3.7 🟡 `CrudListMixin` thiếu error handling

`loadItems()` trong mixin không có try-catch. Nếu `fetchItems()` throw → crash. Các screen dùng mixin (WalletList, CategoryList) không có loading/error state.

### 3.8 🟡 `_loadMore` trong TransactionListScreen không clear error

Nếu `_loadMonth` fail → `_error` được set. Nhưng khi user scroll tiếp → `_loadMore` gọi `_loadMonth` lại mà không clear `_error` trước → error state có thể bị stale.

### 3.9 🟢 `AppTextStyles` fields không phải `const`

Vẫn chưa fix từ round 2. Hầu hết fields dùng `copyWith()` nên không thể `const`, nhưng có thể dùng `static final` thay `static` để tránh re-create.

### 3.10 🟢 `SettingScreen` dùng hardcode padding `16` thay vì `AppSpacing.md`

```dart
padding: const EdgeInsets.all(16),  // nên dùng AppSpacing.md
```

### 3.11 🟢 `TransactionItemModel` chưa có `copyWith`/`==`/`hashCode`

3 model chính đã có, nhưng `TransactionItemModel` chưa được cập nhật.

### 3.12 🟢 Unused import `transaction_service.dart` trong `wallet_detail_screen.dart`

```dart
import 'package:vintage_ledger/features/transaction/services/transaction_service.dart';
```
`DashboardData` đã được export qua `transaction_service.dart`, nhưng import trực tiếp `transaction_service.dart` khi chỉ cần `DashboardData` là thừa.

---

## 4. Kết luận

Codebase đã đạt mức **production-ready cho app cá nhân**. Kiến trúc rõ ràng, DB design chắc chắn, type safety tốt, reusability cao. Các vấn đề còn lại chủ yếu là polish nhỏ: 1 syntax error cần fix ngay, còn lại là consistency (enum xuyên suốt, updated_at thực sự được dùng, mixin thêm error handling).
