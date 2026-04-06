# Tasks: Transfer Transaction Type

| # | Task | File(s) | Detail |
|---|------|---------|--------|
| 1 | TransactionType enum | `transaction_type.dart` | Thêm `transfer`, `transferOut`, `transferIn`. Helpers: `isTransfer`, `isTransferOut`, `isTransferIn`. `fromString` handle cả `transfer_out` / `transfer_in` |
| 2 | TransactionModel fields | `transaction.dart`, `transaction_repository.dart` | Thêm `toWalletId`, `toAccountId`, `linkedTransactionId` (nullable). Serialize `to_wallet_id`, `to_account_id`, `linked_transaction_id` |
| 3 | Firestore rules | `firestore.rules` | Thêm `'transfer'`, `'transfer_out'`, `'transfer_in'` vào allowed types cho create + update |
| 4 | WalletService.getWalletsForAccount | `wallet_service.dart` | Method load wallets từ account bất kỳ (dùng cho cross-account picker). Truy cập `accounts/{accountId}/wallets` trực tiếp |
| 5 | TransactionService.createTransfer | `transaction_service.dart` | Same-account: atomic trừ source + cộng dest + 1 txn doc. Cross-account: batch write 2 txn docs (transfer_out + transfer_in) + update 2 wallets, linked bằng ID |
| 6 | TransactionService.deleteTransaction | `transaction_service.dart` | Handle transfer: revert 2 wallets. Handle transfer_out/transfer_in: revert local wallet + xóa linked txn ở account kia + revert wallet kia |
| 7 | TypeSelector 3 pills | `type_selector.dart` | Thêm pill `transfer`. Nhận `types` list thay vì hardcode 2 |
| 8 | TransactionFormScreen transfer mode | `transaction_form_screen.dart` | Khi transfer: ẩn category/recurring/budget. Hiện account+wallet picker cho source + dest. Load wallets từ tất cả accounts. Validate source ≠ dest |
| 9 | Exclude transfers từ thống kê | `transaction_list_screen.dart`, `home_screen.dart`, `transaction_service.dart` | Summary totals, today expense, monthly dashboard: filter `!isTransfer` |
| 10 | Transfer story + feed | `transaction_story.dart`, `transaction_feed_item.dart` | transfer → "chuyển {amount} 💸", transfer_out → "chuyển {amount} 💸 → {dest}", transfer_in → "nhận {amount} 💸 từ {source}". Subtitle hiện wallet/account names |
| 11 | L10n keys | `app_vi.dart`, `app_en.dart` | `transfer`, `fromWallet`, `toWallet`, `fromAccount`, `toAccount`, `sameWalletError`, `transferOut`, `transferIn` |
