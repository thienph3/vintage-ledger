# Tasks Round 5 — Vintage Ledger

> Ref: [docs/reviews/code-review-round-5.md](../reviews/code-review-round-5.md)

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Xóa `WelcomeScreen` file | `onboarding/screens/welcome_screen.dart` vẫn tồn tại trên disk dù không còn import. Xóa file. | ✅ |
| 2 | Fix hardcode padding trong `WalletFormScreen` | `EdgeInsets.all(16)` → `AppSpacing.md`. | ✅ |
| 3 | `WalletService.updateWallet` copy `accountId` | Wallet mới tạo trong update không copy `accountId` từ existing → default `'local'`. | ✅ |
| 4 | `CategoryService.updateCategory` copy `accountId` | Tương tự #3 — Category update mất `accountId`. | ✅ |
| 5 | `FamilyFormScreen` error text dùng `AppTextStyles.error` | Inline `TextStyle(color: Colors.red)` → `AppTextStyles.error`. | ✅ |
| 6 | Thêm l10n keys `leaveFamilyConfirm` + `deleteFamilyConfirm` | `FamilyDetailScreen` dùng `deleteWalletConfirm` cho cả leave và delete family. Thêm keys riêng. | ✅ |
| 7 | `_pullWallets` bỏ set `balance` từ Firestore | Push đã strip balance, pull nên bỏ field này vì `recalculateBalance` chạy sau. | ✅ |
| 8 | `TransactionService.createTransaction` set `account_id` | Insert map thiếu `account_id` → default `'local'`. Thêm `'account_id': _accountId`. | ✅ |
| 9 | Tạo `firestore.indexes.json` | Sync pull query `updated_at >` cần Firestore composite index. Tạo index config. | ✅ |
| 10 | Thêm `firestore.rules` vào `firebase.json` deploy | File rules tạo nhưng chưa config deploy. | ✅ |
| 11 | `SampleDataService` truy cập DB trực tiếp | Acceptable cho seed data — batch insert cần raw DB access. | Won't fix |
