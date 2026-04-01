# Tasks: Data Consistency (Atomic Balance)

> Đảm bảo balance luôn đúng 100% bằng Firestore transactions.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Status |
|---|------|--------|--------|
| 1 | Atomic createTransaction | `runTransaction`: add transaction doc + update wallet balance trong 1 atomic operation | ✅ |
| 2 | Atomic updateTransaction | `runTransaction`: read old → revert old balance → update doc → apply new balance. Hỗ trợ wallet change (old ≠ new wallet) | ✅ |
| 3 | Atomic deleteTransaction | `runTransaction`: read transaction → revert balance → delete doc | ✅ |
| 4 | Refactor TransactionService | Chuyển từ sequential writes → `firestore.runTransaction()`. Đọc wallet doc bằng `txn.get()` trong transaction context | ✅ |
| 5 | Refactor FirestoreRepository | Thêm `collection` getter (public) + `firestore` getter để service dùng trong `runTransaction` | ✅ |
| 6 | Balance recalculation tool | `WalletService.recalculateBalance(walletId)` — query tất cả transactions, tính lại balance. Dùng fix data cũ | ✅ |
| 7 | Test atomic operations | Chưa verify — cần flutter test environment | ⏳ |
