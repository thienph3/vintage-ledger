# Tasks: Data Consistency (Atomic Balance)

> Đảm bảo balance luôn đúng 100% bằng Firestore transactions.

## Phụ thuộc
- Không

## Tasks

| # | Task | Mô tả | Ưu tiên |
|---|------|--------|---------|
| 1 | Atomic createTransaction | Wrap `add transaction doc` + `update wallet balance` trong `FirebaseFirestore.instance.runTransaction()` | 🔴 |
| 2 | Atomic updateTransaction | Wrap `read old` + `revert old balance` + `update transaction doc` + `apply new balance` trong 1 Firestore transaction | 🔴 |
| 3 | Atomic deleteTransaction | Wrap `read transaction` + `delete doc` + `revert balance` trong 1 Firestore transaction | 🔴 |
| 4 | Refactor TransactionService | Chuyển 3 methods trên từ sequential writes → `runTransaction()`. Cần đọc wallet doc bằng `transaction.get()` thay vì `getById()` | 🔴 |
| 5 | Refactor FirestoreRepository | Thêm helper `collectionRef(accountId)` public để TransactionService có thể dùng trong `runTransaction` context | 🟡 |
| 6 | Balance recalculation tool | Method `recalculateBalance(walletId)` — query tất cả transactions của wallet, tính lại balance. Dùng để fix data cũ bị sai | 🟡 |
| 7 | Test atomic operations | Verify: tạo transaction → balance đúng, update → balance đúng, delete → balance revert đúng | 🟢 |
