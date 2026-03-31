# Tasks Round 4 — Vintage Ledger

> Ref: [docs/reviews/code-review-round-4.md](../reviews/code-review-round-4.md)

| # | Task | Mô tả | Status |
|---|---|---|---|
| 1 | Services truyền `accountId` khi query | `WalletService.getWallets`, `TransactionService.getDashboard`, `CategoryService.getCategories/ByType` đều gọi repo với default `'local'`. Cần đọc `sl.appState.currentAccountId` và truyền xuống. | ✅ |
| 2 | Fix wallet_id mapping khi pull cross-device | Pull transaction từ Firestore có `wallet_id` là local ID của device push. Device khác pull sẽ FK mismatch. Cần lưu/map wallet bằng `remote_id` thay vì local `id`. | ✅ |
| 3 | Xóa `WelcomeScreen` dead code | `WelcomeScreen` không còn reachable từ `main.dart`. Xóa file + import. | ✅ |
| 4 | Không push `balance` lên Firestore | `_pushCollection` push cả `balance` field cho wallets. Nên strip vì balance là computed field — recalculate khi pull. | ✅ |
| 5 | Thêm index cho `account_id` + `is_synced` | Query sync dirty records chạy trên 3 bảng không có index. Thêm composite index. | ✅ |
| 6 | Fix `_maybeImportFromCloud` logic | Check `dirtyCount == 0` không đúng nghĩa local empty. Nên check wallet count = 0 cho account. | ✅ |
| 7 | Hardcode `'Account'` trong SettingScreen | Dùng string literal thay vì `S.of(context, ...)`. Thêm l10n key `account`. | ✅ |
| 8 | Fix l10n key sai trong FamilyDetailScreen | Dùng `deleteCategoryConfirm` cho confirm remove member. Thêm key `removeMemberConfirm`. | ✅ |
| 9 | Thêm `copyWith`/`==`/`hashCode` cho `Account` model | Các model khác đã có, `Account` chưa. | ✅ |
| 10 | Thêm error display trong `FamilyFormScreen` | `_save` catch exception nhưng không show error message. Thêm `_error` state + hiển thị. | ✅ |
| 11 | Cải thiện email validation | `contains('@')` quá lỏng. Thêm check `contains('.')` hoặc regex. | ✅ |
| 12 | Cập nhật test files cho model changes | Models thêm `accountId`, `isSynced`, `remoteId` nhưng tests chưa cập nhật. | ✅ |
| 13 | `AccountService.deleteFamily` dùng batch delete | Loop delete subcollections sẽ timeout nếu data lớn. Dùng `WriteBatch`. | ✅ |
| 14 | `SyncService._pushTransactions` dùng repository thay vì trực tiếp DB | Gọi `AppDatabase.instance.database` trong service vi phạm layer architecture. | ✅ |
| 15 | Restrict Firebase API key | Restrict key trong Firebase Console (Android app restriction). Cân nhắc `.gitignore` cho `firebase_options.dart` nếu repo public. | ✅ |
