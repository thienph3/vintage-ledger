# Tasks: Firestore Indexes

> Tất cả query hoạt động ổn định, không lỗi index.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Audit tất cả queries | Scan TransactionRepository, BudgetRepository, AccountService — liệt kê tất cả query có `where` + `orderBy` trên khác field | 🔴 |
| 2 | transactions: wallet_id + date | Composite index cho `where('wallet_id') + orderBy('date', descending)` — dùng trong watchRecent, watchByDateRange, getRecent, getByDateRange | 🔴 |
| 3 | transactions: date range | Composite index cho `where('date', >=) + where('date', <=) + orderBy('date', descending)` | 🔴 |
| 4 | categories: type + name | Composite index cho `where('type') + orderBy('name')` — dùng trong watchByType, getByType | 🟡 |
| 5 | budgets: category_id | Single field index cho `where('category_id')` — dùng trong getByCategoryId | 🟡 |
| 6 | activities: created_at DESC | Single field index cho `orderBy('created_at', descending)` — dùng trong watchActivities | 🟡 |
| 7 | Update firestore.indexes.json | Tạo/cập nhật file `firestore.indexes.json` với tất cả indexes trên | 🔴 |
| 8 | Deploy indexes | `firebase deploy --only firestore:indexes` | 🟡 |
