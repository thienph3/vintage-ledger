# Feature: Firebase Sync (Dual Database)

## Tổng quan

SQLite local + Firebase Firestore cloud. App luôn đọc/ghi từ SQLite (offline-first), Firestore chỉ dùng để sync giữa các device khi user chủ động trigger.

> Firestore schema và account concept xem chi tiết tại [user-family-management.md](user-family-management.md).

## Spark Plan (free) — Giới hạn

| Resource | Giới hạn/ngày | Ghi chú |
|---|---|---|
| Reads | 50.000 | Mỗi lần get 1 document = 1 read |
| Writes | 20.000 | Insert/update = 1 write |
| Deletes | 20.000 | |
| Storage | 1 GiB | |

## Chiến lược tối ưu

| Chiến lược | Tiết kiệm | Cách làm |
|---|---|---|
| Lazy sync (không realtime) | Reads | `get()` thay `snapshots()`, chỉ sync khi user bấm |
| Incremental sync | Reads | Chỉ query `WHERE updated_at > lastSyncAt` |
| Dirty flag | Writes | Chỉ push records có `is_synced = 0` |
| Batch writes | Writes | `WriteBatch` gom tối đa 500 ops/batch |
| Embed transaction_items | Storage + Reads | Items nằm trong transaction document, không tạo subcollection |
| Không lưu balance | Storage | Tính lại từ transactions khi pull |
| Không sync settings | Writes | locale, setup_done chỉ lưu local |

## SQLite Schema Changes

```sql
-- Account context
ALTER TABLE wallets ADD COLUMN account_id TEXT NOT NULL DEFAULT 'local';
ALTER TABLE transactions ADD COLUMN account_id TEXT NOT NULL DEFAULT 'local';
ALTER TABLE categories ADD COLUMN account_id TEXT NOT NULL DEFAULT 'local';

-- Sync metadata
ALTER TABLE wallets ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1;
ALTER TABLE wallets ADD COLUMN remote_id TEXT;

ALTER TABLE transactions ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transactions ADD COLUMN remote_id TEXT;
ALTER TABLE transactions ADD COLUMN created_by TEXT;

ALTER TABLE categories ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 1;
ALTER TABLE categories ADD COLUMN remote_id TEXT;
```

| Column | Mô tả |
|---|---|
| `account_id` | `'local'` nếu chưa login, Firestore accountId nếu đã login |
| `is_synced` | `0` = dirty (cần push), `1` = đã sync |
| `remote_id` | Firestore document ID (khác SQLite auto-increment ID) |
| `created_by` | userId tạo transaction (hữu ích cho family account) |

## Sync Flow

### Push (Local → Cloud)

```
Với mỗi account trong user.account_ids:
  1. SELECT * FROM wallets|transactions|categories
     WHERE account_id = ? AND is_synced = 0
  2. WriteBatch → accounts/{accountId}/wallets|transactions|categories
  3. UPDATE SET is_synced = 1
```

### Pull (Cloud → Local)

```
Với mỗi account trong user.account_ids:
  1. GET accounts/{accountId}/wallets WHERE updated_at > lastPullAt
  2. GET accounts/{accountId}/transactions WHERE updated_at > lastPullAt
  3. GET accounts/{accountId}/categories WHERE updated_at > lastPullAt
  4. UPSERT vào SQLite (INSERT OR REPLACE by remote_id)
  5. Recalculate wallet balances
```

### Soft Delete

Records xóa trên device A cần sync sang device B:
- Không DELETE thật — set `deleted_at = timestamp`
- Pull sẽ thấy record có `deleted_at` → xóa khỏi SQLite local
- Cleanup: records có `deleted_at` > 30 ngày → xóa thật trên Firestore

### Conflict Resolution

**Last-write-wins** — record có `updated_at` lớn hơn thắng. Đơn giản, phù hợp app cá nhân/family nhỏ.

## Ước tính usage

Giả sử sync 2 lần/ngày:

| Scenario | Reads | Writes | % giới hạn |
|---|---|---|---|
| 1 user, 1 account | ~40 | ~10 | < 0.1% |
| 2 users, 1 family | ~120 | ~30 | < 0.3% |
| 5 users, 2 families | ~400 | ~80 | < 1% |

## Dependencies

```yaml
firebase_core: ^3.x
cloud_firestore: ^5.x
firebase_auth: ^5.x
connectivity_plus: ^6.x
```

## UI

- **Account Picker**: nút "🔄 Đồng bộ" sync tất cả accounts
- **Settings**: section Sync — last sync time, nút "Sync now"
- **AppBar**: badge dot khi có data chưa sync
