# Tasks: Data Layer V2 (Firestore-first)

> Chuyển từ local-first + manual sync → Firestore-first với realtime listeners + offline cache.

## Phụ thuộc
- Hoàn thành trước khi làm các feature khác (foundation change)

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Tạo FirestoreRepository base | Abstract class với CRUD methods dùng Firestore collection reference, hỗ trợ realtime snapshots | ✅ |
| 2 | WalletFirestoreRepo | Implement cho wallets: add, update, delete, watchAll (Stream), watchById | ✅ |
| 3 | CategoryFirestoreRepo | Implement cho categories: add, update, delete, watchAll, watchByType | ✅ |
| 4 | TransactionFirestoreRepo | Implement cho transactions: add, update, delete, watchRecent, watchByDateRange, embedded items | ✅ |
| 5 | Bật Firestore offline persistence | `Settings(persistenceEnabled: true, cacheSizeBytes: UNLIMITED)` trong main.dart | ✅ |
| 6 | Refactor WalletService → Stream-based | Thay `Future<List<Wallet>>` bằng `Stream<List<Wallet>>`, dùng StreamBuilder trên UI | ✅ |
| 7 | Refactor CategoryService → Stream-based | Tương tự wallet, stream categories theo accountId | ✅ |
| 8 | Refactor TransactionService → Stream-based | Stream recent transactions, stream by date range | ✅ |
| 9 | Refactor HomeScreen dùng StreamBuilder | Thay loadData() + setState bằng StreamBuilder cho wallets | ✅ |
| 10 | Refactor WalletDetailScreen dùng StreamBuilder | Realtime balance via stream | ✅ |
| 11 | Refactor list screens dùng StreamBuilder | WalletListScreen, CategoryListScreen → StreamBuilder | ✅ |
| 12 | Balance tính bằng client-side | WalletService.updateBalance() khi create/update/delete transaction | ✅ |
| 13 | Xóa SQLite layer | Xóa database.dart, tất cả SQLite repositories | ✅ |
| 14 | Xóa sync-related code | Xóa is_synced, remote_id, sync_deletes, dirty count, tombstone logic | ✅ |
| 15 | Xóa SyncService + SyncRepository | Xóa toàn bộ features/sync/ | ✅ |
| 16 | Anonymous auth cho user chưa login | Firebase Anonymous Auth, auto sign-in, link to email khi upgrade | ✅ |
| 17 | Optimistic UI | Firestore offline persistence handles this automatically | ✅ |
| 18 | Error handling cho writes | try/catch + showErrorSnackBar trong tất cả form saves và delete actions | ✅ |
| 19 | Network status indicator | NetworkStatusBanner dùng Firestore snapshot metadata, hiển thị ở HomeScreen | ✅ |
| 20 | Server timestamps | Dùng `FieldValue.serverTimestamp()` trong FirestoreRepository base | ✅ |
