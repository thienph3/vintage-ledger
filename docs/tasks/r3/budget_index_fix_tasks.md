# Tasks: Budget Composite Index Fix

> Tất cả budget queries chạy ổn định, không lỗi index.

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Composite index cho checkBudget | `transactions`: category_id ASC + type ASC + date ASC | ✅ |
| 2 | Composite index cho getBudgetStatuses | `transactions`: type ASC + date ASC | ✅ |
| 3 | Update firestore.indexes.json | Thêm 2 indexes, tổng 5 composite indexes | ✅ |
| 4 | Deploy indexes | `firebase deploy --only firestore:indexes` | ⏳ |
