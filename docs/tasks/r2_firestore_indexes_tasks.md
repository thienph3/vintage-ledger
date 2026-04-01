# Tasks: Firestore Indexes

> Tất cả query hoạt động ổn định, không lỗi index.

## Phụ thuộc
- Không

## Audit kết quả

| Query | Collection | Fields | Index type |
|---|---|---|---|
| Recent by wallet | transactions | `wallet_id` + `date DESC` | **Composite** |
| Date range by wallet | transactions | `wallet_id` + `date ASC` | **Composite** |
| Categories by type | categories | `type` + `name ASC` | **Composite** |
| Date range (no wallet) | transactions | `date` range + `date DESC` | Auto-indexed |
| Recent (no wallet) | transactions | `date DESC` | Auto-indexed |
| All categories | categories | `name ASC` | Auto-indexed |
| Budget by category | budgets | `category_id` | Auto-indexed |
| Activities | activities | `created_at DESC` | Auto-indexed |
| Transactions by wallet | transactions | `wallet_id` | Auto-indexed |

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Audit tất cả queries | 9 queries identified: 3 cần composite index, 6 auto-indexed | ✅ |
| 2 | transactions: wallet_id + date DESC | Composite index cho watchRecent/getRecent với walletId filter | ✅ |
| 3 | transactions: wallet_id + date ASC | Composite index cho watchByDateRange/getByDateRange với walletId filter | ✅ |
| 4 | categories: type + name ASC | Composite index cho watchByType/getByType | ✅ |
| 5 | budgets: category_id | Auto-indexed (single field) — không cần composite | ✅ |
| 6 | activities: created_at DESC | Auto-indexed (single field) — không cần composite | ✅ |
| 7 | Update firestore.indexes.json | 3 composite indexes, xóa 6 indexes cũ (updated_at, deleted_at từ sync era) | ✅ |
| 8 | Deploy indexes | `firebase deploy --only firestore:indexes` — cần chạy thủ công | ⏳ |
