# Task List Round 2 — Vintage Ledger

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Thêm `ON DELETE CASCADE` cho FK wallet_id | `transactions.wallet_id` FK không có ON DELETE action → nếu gọi `WalletRepository.delete` trực tiếp sẽ FK violation. Thêm `ON DELETE CASCADE`. | ✅ chưa verify |
| 2 | Thêm `ON DELETE RESTRICT` cho FK category_id | `transactions.category_id` FK không có ON DELETE action → xóa category đang dùng sẽ crash. Thêm `ON DELETE RESTRICT` và handle ở UI. | ✅ chưa verify |
| 3 | Thêm DB constraints cho `amount` và `type` | `amount` có thể null/âm, `type` có thể là bất kỳ string. Thêm `NOT NULL CHECK(amount > 0)` và `CHECK(type IN ('income','expense'))`. | ✅ chưa verify |
| 4 | Wrap `deleteAllByWallet` trong DB transaction | `TransactionRepository.deleteAllByWallet` xóa items + transactions trong 2 queries riêng, không atomic. Wrap trong `db.transaction()`. | ✅ chưa verify |
| 5 | Thống nhất datetime convention | `wallets.created_at` lưu ISO string, `transactions.date` lưu epoch int. Chuyển `created_at` sang INTEGER (epoch) cho nhất quán. | ✅ chưa verify |
| 6 | Dùng enum cho transaction type | `'income'`/`'expense'` string literals rải rác khắp codebase. Tạo `enum TransactionType` và dùng xuyên suốt models/services/widgets. | ✅ chưa verify |
| 7 | Tách `DashboardData` ra file riêng | `DashboardData` class nằm trong `transaction_service.dart`. Tách ra `models/dashboard_data.dart` cho đúng convention. | ✅ chưa verify |
| 8 | Chuyển `home_screen.dart` vào folder `home/` | `home_screen.dart` nằm trực tiếp trong `features/` thay vì trong feature folder. Chuyển vào `features/home/screens/`. | ✅ chưa verify |
| 9 | DI xuyên suốt service layer | `WalletService` tạo `TransactionService()` nội bộ, `SampleDataService` tạo services trực tiếp. Chuyển sang dùng `sl` hoặc inject qua constructor. | ✅ chưa verify |
| 10 | Thêm error handling cho `TransactionListScreen` | `_initialLoad`, `_loadMonth` không có try-catch. Thêm error handling + hiển thị error state. | ✅ chưa verify |
| 11 | Xóa inline `floatingLabelBehavior` và `border` trong `WalletFormScreen` | Vi phạm style guide: đã config trong `InputDecorationTheme` nhưng vẫn override inline. Xóa để dùng theme. | ✅ chưa verify |
| 12 | Thêm `copyWith`, `==`, `hashCode` cho models | `Wallet`, `TransactionModel`, `Category` chỉ có `toMap`/`fromMap`. Thêm `copyWith()` để tránh tạo object thủ công, `==`/`hashCode` để so sánh. | ✅ chưa verify |
| 13 | Cache chart data trong `DashboardData` | `ChartSection` tính `_dailyData`, `_expenseByCategory` mỗi lần rebuild. Tính sẵn trong `DashboardData` hoặc cache trong `ChartSection` state. | ✅ chưa verify |
| 14 | Batch insert trong `SampleDataService` | `generate()` tạo ~60-90 transactions tuần tự (1 DB transaction mỗi cái). Batch insert để tăng tốc onboarding. | ✅ chưa verify |
| 15 | Thêm `updated_at` cho wallets và transactions | Không track thời điểm sửa record. Thêm `updated_at INTEGER` column cho audit/sync. | ✅ chưa verify |
| 16 | Mở rộng test coverage | Chỉ có test cho formatters. Thêm test cho TransactionType enum, Wallet/TransactionModel/Category models (copyWith, ==, fromMap/toMap). | ✅ chưa verify |
| 17 | Chuẩn hóa `onboarding/` folder structure | `onboarding/` không theo cấu trúc feature chuẩn (thiếu `screens/`, `services/` subfolder). Tách cho consistency. | ✅ chưa verify |
