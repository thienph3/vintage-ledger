# Tasks Round 6 — Vintage Ledger

> Ref: [docs/reviews/code-review-round-6.md](../reviews/code-review-round-6.md)

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Xóa `onboarding/` feature | `SampleDataService` không còn ai import. Xóa toàn bộ `onboarding/` folder. | ✅ |
| 2 | HomeScreen bottom padding comment | `SizedBox(height: 80)` hardcode → thêm comment giải thích. | ✅ |
| 3 | `_pushTransactions` skip record nếu wallet chưa có remote_id | Nếu `walletRemoteId == null` hoặc `categoryRemoteId == null` → `continue` thay vì push local int. | ✅ |
| 4 | Bỏ try-catch rethrow thừa trong `syncAccount` | `try { ... } catch (e) { rethrow; }` → bỏ. | ✅ |
| 5 | `WalletFormScreen.save` simplify | Bỏ Wallet object thừa, gọi service trực tiếp với name + balance. Xóa unused Wallet import. | ✅ |
| 6 | Thêm unit test cho `upsertByRemoteId` | 4 test cases: insert new, update existing, skip local newer, overwrite remote newer. Thêm `AppDatabase.resetForTest()`. | ✅ |
