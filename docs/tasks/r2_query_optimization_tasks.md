# Tasks: Query Optimization

> Giảm Firestore reads, load nhanh hơn, tách biệt queries.

## Phụ thuộc
- Firestore Indexes (composite indexes cần có trước)

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Tách BudgetService khỏi getDashboard | `getBudgetStatuses()` hiện gọi `getDashboard()` (load toàn bộ monthly). Thay bằng query trực tiếp: `where('type', 'expense') + where('date', >=monthStart)` rồi group by categoryId | 🔴 |
| 2 | Tách checkBudget | `checkBudget(categoryId)` query chỉ transactions của 1 category trong tháng thay vì load toàn bộ dashboard | 🔴 |
| 3 | TransactionListScreen lazy loading | Thay `getDashboard()` bằng query trực tiếp `getByDateRange(start, end)` từ TransactionRepository. Load tháng cũ hơn khi scroll | 🔴 |
| 4 | Cache DashboardData | Cache kết quả getDashboard trong HomeScreen state, chỉ reload khi pull-to-refresh hoặc sau write operation | 🟡 |
| 5 | Limit query results | Thêm `.limit()` cho các query không cần toàn bộ: activities (20), recent transactions (5), budgets (20) | 🟡 |
| 6 | Firestore read counter (debug) | Debug widget hiển thị số Firestore reads trong session — giúp monitor cost | 🟢 |
