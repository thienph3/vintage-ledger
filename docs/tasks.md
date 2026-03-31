# Task List — Vintage Ledger

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Wrap DB operations trong transaction | `TransactionService` (create/update/delete) thực hiện update wallet balance + insert/update transaction riêng lẻ → nếu fail giữa chừng thì balance sai. Cần wrap trong `db.transaction()` để đảm bảo atomicity. | ✅ chưa verify |
| 2 | Bật PRAGMA foreign_keys = ON | SQLite mặc định tắt foreign key enforcement. Thêm `onConfigure` callback trong `AppDatabase._initDB` để bật `PRAGMA foreign_keys = ON`. Đồng thời khai báo `FOREIGN KEY` cho bảng `transactions`. | ✅ chưa verify |
| 3 | Fix icon code point mismatch | Seed categories trong `database.dart` dùng hardcode code point (vd: `0xe25a`) không khớp với `kCategoryIconMap` trong `category_icons.dart` (vd: `0xe57a`) → icon hiển thị sai, fallback về `help_outline`. Cần đồng bộ lại. | ✅ chưa verify |
| 4 | Fix DropdownButtonFormField dùng sai prop | `transaction_form_screen.dart` và `category_dropdown.dart` dùng `initialValue` thay vì `value` → không reactive khi state thay đổi. Đổi sang `value`. | ✅ chưa verify |
| 5 | Fix list item dùng Colors.white thay vì AppColors.paper | `WalletListScreen` và `CategoryListScreen` dùng `Colors.white` cho list item background thay vì `AppColors.paper` → vi phạm style guide. | ✅ chưa verify |
| 6 | Thêm database index | Bảng `transactions` query thường xuyên theo `wallet_id` và `date` nhưng không có index. Thêm `CREATE INDEX` cho 2 cột này. | ✅ chưa verify |
| 7 | Fix `date` column type trong schema | Schema khai báo `date TEXT` nhưng code lưu `millisecondsSinceEpoch` (int). Đổi sang `date INTEGER` cho đúng kiểu. | ✅ chưa verify |
| 8 | Extract `showDeleteConfirmation()` helper | Confirm delete dialog copy-paste 4 lần (WalletList, CategoryList, TransactionList, TransactionSection) chỉ khác title/content key. Extract thành 1 function chung. | ✅ chưa verify |
| 9 | Extract `LedgerListTile` widget | Inline `BoxDecoration` (background, borderRadius 12, shadow) lặp lại giống hệt ở `WalletListScreen` và `CategoryListScreen`. Extract thành widget chung. | ✅ chưa verify |
| 10 | Tạo `NavigatorX` extension | Pattern `Navigator.push → MaterialPageRoute → if (result == true) reload` lặp lại 15+ lần. Tạo extension method `context.pushScreen(widget)` để giảm boilerplate. | ✅ chưa verify |
| 11 | Thêm `AsyncContent` widget | Không có loading/error/empty state chung. HomeScreen, WalletDetailScreen không có loading indicator → flash trống khi load data. Tạo widget `AsyncContent(loading, error, isEmpty, child)`. | ⬜ |
| 12 | Thêm error handling ở UI layer | Hầu hết screen gọi service không try-catch → crash nếu DB lỗi. Wrap `loadData()` trong try-catch, hiển thị error state hoặc snackbar. | ⬜ |
| 13 | Extract `IncomeExpenseSummaryRow` widget | Pattern "2 cột income/expense chia bởi divider dọc" lặp lại ở HomeScreen, TransactionListScreen, SummaryView. Extract thành widget chung. | ✅ chưa verify |
| 14 | Tạo `DashboardData` + service method | `loadData()` logic trùng ~80% giữa `HomeScreen` và `WalletDetailScreen` (chỉ khác walletId filter). Extract vào `TransactionService.getDashboard({walletId})`. | ⬜ |
| 15 | Refactor `TransactionSection` giảm callback | `TransactionSection` nhận 3 callback gần giống nhau ở cả HomeScreen và WalletDetailScreen. Cho nó tự handle navigation/delete, chỉ nhận `walletId` + `onDataChanged`. | ⬜ |
| 16 | Extract `FormSaveButton` widget | 3 form screen đều có pattern full-width ElevatedButton với text "Lưu"/"Cập nhật" theo isEdit. Extract thành widget chung. | ✅ chưa verify |
| 17 | Hardcode Vietnamese trong AuthService | `AuthService._reason()` hardcode tiếng Việt cho biometric dialog. Truyền `localizedReason` từ caller (LockScreen/AutoLockWrapper) thay vì hardcode. | ⬜ |
| 18 | Fix N+1 query trong `_attachItems` | `TransactionService._attachItems` gọi 1 query per transaction để load items. Batch load bằng `WHERE transaction_id IN (...)` rồi group theo id. | ✅ chưa verify |
| 19 | Thêm `recalculateBalance()` | Wallet balance denormalized, cập nhật thủ công → có thể drift nếu bug. Thêm function tính lại balance từ tổng transactions để verify/repair. | ✅ chưa verify |
| 20 | Viết unit test cho services | Không có test nào. Ưu tiên: `AmountFormatter` (pure function), `TransactionService` (balance logic), `WalletService.deleteWallet` (cascade). | ⬜ |
| 21 | Dependency injection cho services | Mỗi screen tự tạo `new Service()` → không mock được khi test, tạo nhiều instance thừa. Dùng singleton hoặc DI (get_it, Provider). | ⬜ |
| 22 | Tạo `CrudListScreen<T>` hoặc mixin | `WalletListScreen` và `CategoryListScreen` trùng 60-70% code (load, delete, confirmDelete, openForm, build ListView). Extract thành generic pattern. | ⬜ |
| 23 | Xóa dead code | `PrimaryButton` và `CategorySection` widget không được sử dụng ở đâu. Xóa hoặc integrate. | ⬜ |
| 24 | Chuyển `rename` sang dev_dependencies | Package `rename` chỉ dùng khi build, không cần trong runtime. Chuyển từ `dependencies` sang `dev_dependencies` trong `pubspec.yaml`. | ⬜ |
| 25 | Batch delete transaction items | `deleteTransaction` xóa items bằng vòng lặp (1 query/item). Dùng `DELETE FROM transaction_items WHERE transaction_id = ?` thay vì loop. | ✅ chưa verify |
| 26 | Xóa `_resetOnInit` flag | `AppDatabase._resetOnInit` là debug flag trong production code. Xóa hoặc chuyển sang build config/environment variable. | ⬜ |
