# Task List Round 3 — Vintage Ledger

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Fix syntax error trong `_onUpgrade` | `database.dart` thiếu `}` đóng block `if (oldVersion < 3)` → compile error. | ✅ chưa verify |
| 2 | Xóa `import 'dart:io'` trong `database.dart` | Dead import, `dart:io` không còn được sử dụng sau khi xóa `_resetOnInit`. | ✅ chưa verify |
| 3 | Chuyển `AmountText.type` sang `TransactionType` | `AmountText` vẫn nhận `type` là `String`, caller phải gọi `.type.value`. Chuyển sang nhận enum, thêm `AmountText.fromBalance` cho balance display. | ✅ chưa verify |
| 4 | Chuyển `Category.type` sang `TransactionType?` | `Category.type` vẫn là `String?`. Đồng bộ với enum cho consistency. Cập nhật `CategoryFormScreen.initialType` tương ứng. | ✅ chưa verify |
| 5 | Set `updated_at` khi update wallet/transaction | Column `updated_at` đã có trong schema nhưng không code nào ghi giá trị. Thêm `DateTime.now().millisecondsSinceEpoch` khi update. | ✅ chưa verify |
| 6 | Thêm error handling cho `CrudListMixin` | `loadItems()` không có try-catch. Thêm `crudLoading`, `crudError` state vào mixin, hiển thị loading/error trong list screens. | ✅ chưa verify |
| 7 | Clear `_error` trước khi `_loadMore` | `TransactionListScreen._loadMore` gọi `_loadMonth` mà không clear `_error` trước → error state có thể stale. | ✅ chưa verify |
| 8 | Đổi `AppTextStyles` fields sang `static final` | Hầu hết fields dùng `copyWith()` nên tạo object mới mỗi lần access. Đổi sang `static final` để tạo 1 lần. | ✅ chưa verify |
| 9 | Thay hardcode padding `16` bằng `AppSpacing.md` trong `SettingScreen` | Vi phạm style guide: dùng literal `16` thay vì design token. | ✅ chưa verify |
| 10 | Thêm `copyWith`/`==`/`hashCode` cho `TransactionItemModel` | 3 model chính đã có, `TransactionItemModel` chưa. | ✅ chưa verify |
| 11 | Cleanup unused import trong `wallet_detail_screen.dart` | Import `transaction_service.dart` trực tiếp khi chỉ cần `DashboardData` (đã export qua service). | ✅ chưa verify |
