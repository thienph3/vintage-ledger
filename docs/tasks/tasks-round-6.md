# Tasks Round 6 — Vintage Ledger

> Ref: [docs/reviews/code-review-round-6.md](../reviews/code-review-round-6.md)

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Xóa `onboarding/` feature | `SampleDataService` không còn ai import. Xóa toàn bộ `onboarding/` folder (services + empty screens dir). | ⬜ |
| 2 | HomeScreen bottom padding dùng constant | `SizedBox(height: 80)` hardcode → extract hoặc comment. | ⬜ |
| 3 | `_pushTransactions` skip record nếu wallet chưa có remote_id | Nếu `walletRemoteId == null` → skip record thay vì push local int lên Firestore. Tương tự cho `categoryRemoteId`. | ⬜ |
| 4 | Bỏ try-catch rethrow thừa trong `syncAccount` | `try { await _pushAccount(...); } catch (e) { rethrow; }` → bỏ try-catch. | ⬜ |
| 5 | `WalletFormScreen.save` simplify | Tạo Wallet object rồi chỉ truyền name + balance — bỏ Wallet object thừa, gọi service trực tiếp. | ⬜ |
| 6 | Thêm unit test cho `upsertByRemoteId` | Last-write-wins logic cần test: local newer skip, remote newer overwrite, new record insert. | ⬜ |
