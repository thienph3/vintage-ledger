# Tasks: Budget Composite Index Fix

> Tất cả budget queries chạy ổn định, không lỗi index.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Thêm composite index cho checkBudget | `transactions`: category_id ASC + type ASC + date DESC — cho `where('category_id') + where('type','expense') + where('date',>=)` | 🔴 |
| 2 | Thêm composite index cho getBudgetStatuses | `transactions`: type ASC + date ASC — cho `where('type','expense') + where('date',>=) + where('date',<=)` | 🔴 |
| 3 | Update firestore.indexes.json | Thêm 2 indexes trên vào file | 🔴 |
| 4 | Deploy indexes | `firebase deploy --only firestore:indexes` | 🟡 |
