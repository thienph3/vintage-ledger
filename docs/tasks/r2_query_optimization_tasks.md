# Tasks: Query Optimization

> Giảm Firestore reads, load nhanh hơn, tách biệt queries.

## Phụ thuộc
- Firestore Indexes ✅

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Tách BudgetService khỏi getDashboard | `getBudgetStatuses()` query expense transactions trực tiếp bằng `where('type','expense') + where('date',>=)`, group by categoryId. Không gọi getDashboard | ✅ |
| 2 | Tách checkBudget | `checkBudget(categoryId)` query `where('category_id') + where('type','expense') + where('date',>=)` — chỉ 1 category, không load toàn bộ | ✅ |
| 3 | TransactionListScreen lazy loading | Dùng `TransactionRepository.getByDateRange()` trực tiếp per month. Scroll → load tháng cũ hơn. Không gọi getDashboard | ✅ |
| 4 | Cache DashboardData | HomeScreen cache `_dashboard` trong state, chỉ reload khi pull-to-refresh hoặc onDataChanged (đã đúng pattern) | ✅ |
| 5 | Limit query results + expose getByDateRange | TransactionService expose `getByDateRange()`. Activities đã có limit 20. Wallets/categories/budgets ít records nên không cần limit | ✅ |
| 6 | Firestore read counter (debug) | `ReadCounter` class + hook vào `FirestoreRepository.getById/getAll` auto-increment | ✅ |
