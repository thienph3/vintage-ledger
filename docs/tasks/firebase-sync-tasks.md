# Tasks — Firebase Sync

> Ref: [docs/features/firebase-sync.md](../features/firebase-sync.md)
> Depends on: [user-family-tasks.md](user-family-tasks.md) Phase 1–2 hoàn thành trước

## Phase 4A: Schema + Infrastructure

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Thêm `cloud_firestore` + `connectivity_plus` dependencies | Thêm vào `pubspec.yaml`. | ✅ |
| 2 | DB migration: thêm sync columns | Thêm `is_synced INTEGER DEFAULT 1`, `remote_id TEXT` vào wallets, transactions, categories. Thêm `created_by TEXT` vào transactions. Bump DB version. | ✅ |
| 3 | Cập nhật models: thêm sync fields | `Wallet`, `TransactionModel`, `Category` thêm `isSynced`, `remoteId`. `TransactionModel` thêm `createdBy`. Cập nhật `toMap`/`fromMap`/`copyWith`. | ✅ |
| 4 | Auto set `is_synced = 0` khi create/update/delete | Mọi write operation trong repositories tự động mark record dirty. | ✅ |
| 5 | Tạo `SyncService` skeleton | Class với methods: `pushAll()`, `pullAll()`, `syncAccount(accountId)`. Inject vào `ServiceLocator`. | ✅ |
| 6 | Tạo `SyncRepository` | Helper đọc/ghi Firestore: `pushWallets`, `pushTransactions`, `pushCategories`, `pullWallets`, `pullTransactions`, `pullCategories`. | ✅ |

## Phase 4B: Push (Local → Cloud)

| # | Task | Mô tả | Status |
|---|---|---|---|
| 7 | Implement push wallets | Query `WHERE account_id = ? AND is_synced = 0` → `WriteBatch` → `accounts/{id}/wallets/`. Set `is_synced = 1` sau push. | ✅ |
| 8 | Implement push transactions | Tương tự wallets. Embed `transaction_items` trong document (không tạo subcollection). | ✅ |
| 9 | Implement push categories | Tương tự wallets. | ✅ |
| 10 | Implement push soft deletes | Records có `deleted_at` → push lên Firestore với `deleted_at` field. | ✅ |
| 11 | Lưu `last_push_at` per account | Lưu trong SQLite `settings` table: key = `sync_push_{accountId}`. | ✅ |

## Phase 4C: Pull (Cloud → Local)

| # | Task | Mô tả | Status |
|---|---|---|---|
| 12 | Implement pull wallets | Query `accounts/{id}/wallets WHERE updated_at > lastPullAt` → UPSERT vào SQLite by `remote_id`. | ✅ |
| 13 | Implement pull transactions | Tương tự. Extract embedded `items` → insert vào `transaction_items` table. | ✅ |
| 14 | Implement pull categories | Tương tự wallets. | ✅ |
| 15 | Implement pull soft deletes | Records có `deleted_at` trên Firestore → DELETE khỏi SQLite local. | ✅ |
| 16 | Recalculate wallet balances sau pull | Gọi `AppDatabase.recalculateBalance()` cho mỗi wallet có thay đổi. | ✅ |
| 17 | Lưu `last_pull_at` per account | Lưu trong SQLite `settings` table: key = `sync_pull_{accountId}`. | ✅ |

## Phase 4D: Conflict Resolution + Edge Cases

| # | Task | Mô tả | Status |
|---|---|---|---|
| 18 | Implement last-write-wins | Khi pull: nếu local `updated_at` > remote `updated_at` → giữ local, ngược lại → overwrite. | ✅ |
| 19 | Handle network errors | Check `connectivity_plus` trước sync. Nếu offline → show message, không crash. | ✅ |
| 20 | Handle partial sync failure | Nếu push batch fail giữa chừng → rollback `is_synced` flags. Retry lần sau. | ✅ |
| 21 | Cleanup old soft deletes | Records có `deleted_at` > 30 ngày → xóa thật trên Firestore (tiết kiệm storage). | ✅ |

## Phase 4E: UI

| # | Task | Mô tả | Status |
|---|---|---|---|
| 22 | Thêm nút "🔄 Đồng bộ" trên Account Picker | Tap → sync tất cả accounts. Hiển thị progress. | ⬜ |
| 23 | Thêm section Sync trong Settings | Hiển thị last sync time. Nút "Sync now". | ⬜ |
| 24 | Badge dot trên AppBar khi có dirty data | Đếm records có `is_synced = 0`. Nếu > 0 → hiển thị dot trên icon sync. | ⬜ |
| 25 | Thêm l10n keys cho Sync | `sync`, `syncNow`, `lastSync`, `syncing`, `syncSuccess`, `syncFailed`, `noInternet` — cả vi và en. | ⬜ |
| 26 | Import data từ cloud khi login lần đầu | Sau login + tạo personal account → hỏi "Import data từ cloud?" nếu Firestore có data. | ⬜ |
