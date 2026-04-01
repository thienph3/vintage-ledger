# Tasks: Stream Read Optimization

> Giảm Firestore reads/session. Target < 1000 reads/user/day.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Audit stream usage | Liệt kê tất cả `watchAll`/`watchById` calls: HomeScreen wallets, WalletListScreen, CategoryListScreen, WalletDetailScreen. Xác định cái nào thực sự cần realtime | 🔴 |
| 2 | Replace chart stream → get | ChartSection dùng data từ getDashboard (one-shot), không cần stream. Verify không có stream leak | 🔴 |
| 3 | Replace budget stream → get | BudgetSummaryCard + BudgetListScreen: dùng `getBudgetStatuses()` one-shot thay vì `watchBudgets()` stream | 🟡 |
| 4 | Limit transaction stream | `watchRecent` limit 10 thay vì 5 (đủ cho Home), không stream toàn bộ collection | 🟡 |
| 5 | Dispose streams | Verify tất cả StreamBuilder dispose đúng khi screen unmount. Check không có orphan listeners | 🟡 |
| 6 | Measure before/after | Dùng ReadCounter đo reads cho flow chuẩn: mở app → Home → tạo 1 txn → wallet detail. So sánh trước/sau optimization | 🟢 |
